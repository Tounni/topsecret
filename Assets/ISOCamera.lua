--!Header("Zoom Settings")
--!SerializeField
local zoom : number = 15
--!SerializeField
local zoomMin : number = 10
--!SerializeField
local zoomMax : number = 50
--!SerializeField
local fov : number = 30
--!Header("Defaults")
--!SerializeField
local pitch : number = 30
--!SerializeField
local yaw : number = 45
--!SerializeField
local centerOnCharacterWhenSpawned : boolean = true

--!SerializeField
local mobileZoomSensitivity : number = 1 -- The sensitivity of the zoom on mobile devices

local previousPinchDistance = 1 -- the previous distance value between two touches during a pinch gesture


--!SerializeField
local keepPlayerInView : boolean = true

local CameraMoveStateEnum = {
    None = 0;
    ManualControl = 1;
    Resetting = 2;
    PlayerOffScreenFollow = 3
}

local cameraMoveState = CameraMoveStateEnum.None

local camera = self.gameObject:GetComponent(Camera)
if camera == nil then
    print("HighriseCameraController requires a Camera component on the GameObject its attached to.")
    return
end
local cameraRig : Transform = camera.transform   -- quick reference to the camera's transform

local inertiaVelocity : Vector3 = Vector3.zero;  -- the current velocity of the camera fom inertia
local inertiaMagnitude : number = 0;             -- the magnitude of the current InertiaVelocity (this is an optimization to avoid calculating it every frame)
local inertiaMultiplier : number = 2             -- A multiplier to the inertia force to make it feel more or less initially intense.
local closeMaxInitialInertia : number = 35       -- The maximum amount of force when applying inertia to the panning of the camera at closest zoom
local farMaxInitialIntertia : number = 150       -- The maximum amount of force when applying inertia to the panning of the camera at farthest zoom
local inertiaDampeningFactor : number = 0.93     -- The multiplier used to scale the inertia force back over time.

local playerViewBoundsPercentage : number = 0.7      -- The percentage of the screen that the player can move in without the camera moving to keep them in frame if keepPlayerInView is checked
local playerOutOfViewScreenMoveSpeedMin : number = 0.4  -- The speed of the camera when it moves to keep the player in view. Units are percentage of screenSize per sec
local playerOutOfViewScreenMoveSpeedMax : number = 2.0  -- min is used when the player is close to the bounds, max is used when the player is at the edge or off screen

local resetTime : number = 0
local resetLerpDuration : number = 1.2           -- The duration of the lerp to snap back to character when the camera is reset
local defaultZoom = zoom

local initialZoomOfPinch : number = zoom         -- the zoom level at the start of the pinch gesture
local wasPinching : boolean = false                 -- whether the last frame was pinching (two fingers) or not

local wasPanning : boolean = false
local panTargetStart : Vector3 = Vector3.zero;

local rotation : Vector3 = Vector3.zero          -- the rotation of the camera (.y can be thought of it as the "swivel" of the camera around the Target)
local lastDirection : Vector2 = Vector2.zero        -- the direction of the last frame of the pinch gesture (for rotating the camera with touch controls)
local lastPinchWorldPosition : Vector3 = Vector3.zero

local target = Vector3.zero                      -- the point the camera is looking at

local localCharacterInstantiatedEvent = nil
if centerOnCharacterWhenSpawned then
    localCharacterInstantiatedEvent = client.localPlayer.CharacterChanged:Connect(function(player, character)
        if character then
            OnLocalCharacter(player, character)
        end
    end)

    function OnLocalCharacter(player, character)
        localCharacterInstantiatedEvent:Disconnect()
        localCharacterInstantiatedEvent = nil

       local position = character.gameObject.transform.position
       CenterOn(position)
    end
end

client.Reset:Connect(function(evt)
    if not IsActive() then
        return
    end

    ResetInertia()
    cameraMoveState = CameraMoveStateEnum.Resetting

    resetTime = Time.time
end)

Input.MouseWheel:Connect(function(evt)
    if not IsActive() then
        return
    end

    if evt.delta.y < 0.0 then
        ZoomIn()
        PostZoomMoveTowardsScreenPoint(evt.position)
    else
        ZoomOut()
        PostZoomMoveTowardsScreenPoint(evt.position)
    end
end)

function IsActive()
    return camera ~= nil and camera.isActiveAndEnabled
end

Input.PinchOrDragBegan:Connect(function(evt)
    if not IsActive() then
        return
    end

    cameraMoveState = CameraMoveStateEnum.ManualControl

    lastDirection = Vector2.zero
    lastPinchWorldPosition = Vector3.zero
    wasPanning = false
    wasPinching = false

    previousPinchDistance = evt.distance

    ResetInertia()
end)

Input.PinchOrDragChanged:Connect(function(evt)
    if not IsActive() then
        return
    end

    cameraMoveState = CameraMoveStateEnum.ManualControl

    if Input.isMouseInput then
        if Input.isAltPressed then
            MouseRotateCamera(evt)
        else
            PanCamera(evt)
        end
    else
        if evt.isPinching then
            PinchRotateAndZoomCamera(evt)
        else
            PanCamera(evt)
        end
    end

    wasPinching = evt.isPinching
    wasPanning = not evt.isPinching

    local scaleChange = (1 - evt.distance / previousPinchDistance) * mobileZoomSensitivity

    local newZoom = zoom + (zoom * scaleChange)
    zoom = Mathf.Clamp(newZoom, zoomMin, zoomMax)

    previousPinchDistance = evt.distance

    PostZoomMoveTowardsScreenPoint(evt.position)
end)

Input.PinchOrDragEnded:Connect(function(evt)
    if not IsActive() then
        return
    end

    cameraMoveState = CameraMoveStateEnum.None

    if not Input.isMouseInput then
        ApplyInertia(CalculateWorldVelocity(evt))
    end
end)

local worldUpPlane = Plane.new(Vector3.up, Vector3.new(0,0,0)) -- cached to avoid re-generating every call
function ScreenPositionToWorldPoint(camera, screenPosition)
    -- possibly check for world physics and use that instead of world up plane

    local ray = camera:ScreenPointToRay(screenPosition)

    local success, distance = worldUpPlane:Raycast(ray)
    if not success then
        print("HighriseCameraController Failed to cast ray down into the world. Is the camera not looking down?")
        return Vector3.zero
    end

    return ray:GetPoint(distance)
end

function PanCamera(evt)
    if (not wasPanning) then
        panTargetStart = ScreenPositionToWorldPoint(camera, evt.position)
    end
   
    PanWorldPositionToScreenPosition(panTargetStart, evt.position)
end

function MouseRotateCamera(evt)
    -- Full screen width drag is 360 degrees and full screen height is the pitch range
    local screenDelta = evt.position - (evt.position - evt.deltaPosition)
    local xAngle = screenDelta.x / Screen.width * 360.0
    Rotate(Vector2.new(xAngle, 0))
end

-- Pan the camera on the X/Y plane by the given amount
function Rotate(rotate)
    rotate = Vector2.zero
    rotation = rotation + Vector3.new(rotate.y, rotate.x, 0)
    rotation.y = rotation.y + 3600  -- Ensure positive value
    rotation.y = rotation.y % 360  -- Ensure value is between 0 and 360
end

function ResetZoomScale()
    initialZoomOfPinch = zoom
end

function PinchRotateAndZoomCamera(evt)
    -- New pinch attempt
    if not wasPinching then
        lastPinchWorldPosition = ScreenPositionToWorldPoint(camera, evt.position)
        lastDirection = evt.direction
        ResetZoomScale()
    end

    local deltaAngle = Vector2.SignedAngle(lastDirection, evt.direction)

    if Mathf.Abs(deltaAngle) > 0 then
        Rotate(Vector2.new(deltaAngle, 0))
        UpdatePosition()

        PanWorldPositionToScreenPosition(lastPinchWorldPosition, evt.position)
        UpdatePosition()
        
        lastDirection = evt.direction
        lastPinchWorldPosition = ScreenPositionToWorldPoint(camera, evt.position)
    end

    if evt.scale > 0 then
        local newZoom = initialZoomOfPinch + (initialZoomOfPinch / evt.scale - initialZoomOfPinch)
        zoom = Mathf.Clamp(newZoom, zoomMin, zoomMax)

        PostZoomMoveTowardsScreenPoint(evt.position)
    end
end

function PanWorldPositionToScreenPosition(worldPosition, screenPosition)
    local targetPlane = Plane.new(Vector3.up, worldPosition)

    local ray = camera:ScreenPointToRay(screenPosition)
    local success, distance = targetPlane:Raycast(ray)
    if success then
        local dragAdjustment = -(ray:GetPoint(distance) - worldPosition)
        dragAdjustment.y = 0

        target = target + dragAdjustment
    end
end

function UpdateZoom()
    camera.orthographicSize = zoom
end

function ZoomIn()
    zoom = Mathf.Clamp(zoom - 1, zoomMin, zoomMax)
end

function ZoomOut()
    zoom = Mathf.Clamp(zoom + 1, zoomMin, zoomMax)
end

function PostZoomMoveTowardsScreenPoint(screenPosition)
    local screenPositionVector3 = Vector3.new(screenPosition.x, screenPosition.y, 0)
    local worldPosition = camera:ScreenToWorldPoint(screenPositionVector3)

    UpdateZoom()

    PanWorldPositionToScreenPosition(worldPosition, screenPositionVector3)
end

function ResetInertia()
    inertiaVelocity = Vector3.zero
    inertiaMagnitude = 0
end

local MaxSwipeVelocity = 400 -- the maximum velocity of a swipe to apply inertia with
function CalculateWorldVelocity(evt)
    local velocity = evt.velocity
    velocity.x = Mathf.Clamp(velocity.x, -MaxSwipeVelocity, MaxSwipeVelocity)
    velocity.y = Mathf.Clamp(velocity.y, -MaxSwipeVelocity, MaxSwipeVelocity)

    local screenStart = evt.position
    local screenEnd = evt.position + velocity

    local worldStart = ScreenPositionToWorldPoint(camera, screenStart)
    local worldEnd = ScreenPositionToWorldPoint(camera, screenEnd)

    local result = -(worldEnd - worldStart) -- swiping right means moving the camera left
    return result
end

function ApplyInertia(worldVelocity)
    local t = Easing.Quadratic((zoom - zoomMin) / (zoomMax - zoomMin)) -- closer camera means slower inertia
    local currentMaxVelocity = Mathf.Lerp(closeMaxInitialInertia, farMaxInitialIntertia, t)

    inertiaVelocity = Vector3.ClampMagnitude(worldVelocity * inertiaMultiplier, currentMaxVelocity)
    inertiaMagnitude = inertiaVelocity.magnitude
end

function CenterOn(newTarget, newZoom)
    zoom = newZoom or zoom

    target = newTarget
    zoom = Mathf.Clamp(zoom, zoomMin, zoomMax)
end

function CalculateCameraDistanceToTarget()
    local frustumHeight = zoom
    local distance = 50 --(frustumHeight * 0.5) / math.tan(fov * 0.5 * Mathf.Deg2Rad)
    return distance
end

function CalculateRelativePosition()
    local rotation = Quaternion.Euler(
        pitch + rotation.x,
        yaw + rotation.y,
        0
    )

    local cameraPos = Vector3.back * CalculateCameraDistanceToTarget()
    cameraPos = rotation * cameraPos

    return cameraPos
end

function PanIfPlayerOutOfView() 
    local screenMinX = camera.pixelWidth / 2 - (camera.pixelWidth / 2) * playerViewBoundsPercentage
    local screenMaxX = camera.pixelWidth / 2 + (camera.pixelWidth / 2) * playerViewBoundsPercentage
    
    local screenMinY = camera.pixelHeight / 2 - (camera.pixelHeight / 2) * playerViewBoundsPercentage
    local screenMaxY = camera.pixelHeight / 2 + (camera.pixelHeight / 2) * playerViewBoundsPercentage

    local playerScreenPosVector3 = camera:WorldToScreenPoint(client.localPlayer.character.gameObject.transform.position)
    local playerScreenPos = Vector2.new(playerScreenPosVector3.x, playerScreenPosVector3.y)

    if playerScreenPos.x < screenMinX or playerScreenPos.x > screenMaxX or playerScreenPos.y < screenMinY or playerScreenPos.y > screenMaxY then
        cameraMoveState = CameraMoveStateEnum.PlayerOffScreenFollow

        ResetInertia()

        local targetScreenPosition = Vector2.new(
            Mathf.Clamp(playerScreenPos.x, screenMinX, screenMaxX), 
            Mathf.Clamp(playerScreenPos.y, screenMinY, screenMaxY)
        )
        
        local smallerScreenDimension = Mathf.Min(camera.pixelWidth, camera.pixelHeight)

        local targetDistance = Vector2.Distance(targetScreenPosition, playerScreenPos)
        local speedLerp = Mathf.Clamp01(targetDistance / (smallerScreenDimension * (1-playerViewBoundsPercentage)))

        local panMinSpeed = smallerScreenDimension * playerOutOfViewScreenMoveSpeedMin
        local panMaxSpeed = smallerScreenDimension * playerOutOfViewScreenMoveSpeedMax
        local panSpeed = Mathf.Lerp(panMinSpeed, panMaxSpeed, speedLerp)
        PanWorldPositionToScreenPosition(client.localPlayer.character.gameObject.transform.position, Vector2.MoveTowards(playerScreenPos, targetScreenPosition, panSpeed * Time.deltaTime))
    else
        cameraMoveState = CameraMoveStateEnum.None
    end
end

local InertiaMinVelocity = 0.5; -- prevents the infinite slow drag at the end of inertia
local InertiaStepDuration = 1 / 60; -- each "inertia step" is normalized to 60fps
function UpdateInertia()
    if not Input.isMouseInput and inertiaMagnitude > InertiaMinVelocity then
        local stepReduction = (1.0 - inertiaDampeningFactor) / (InertiaStepDuration / Time.deltaTime)
        local velocityDampener = 1.0 - math.min(math.max(stepReduction, 0), 1)
        inertiaVelocity = inertiaVelocity * velocityDampener
        inertiaMagnitude = inertiaMagnitude * velocityDampener
        target = target + (inertiaVelocity * Time.deltaTime)
    end
end

function UpdatePosition()
    camera.fieldOfView = fov

    cameraRig.position = CalculateRelativePosition() + target;
    cameraRig:LookAt(target)
end

function self:Update()
    if not IsActive() then
        return
    end

    if cameraMoveState == CameraMoveStateEnum.None or cameraMoveState == CameraMoveStateEnum.PlayerOffScreenFollow then
        if keepPlayerInView then
            PanIfPlayerOutOfView();
        end
    elseif cameraMoveState == CameraMoveStateEnum.Resetting then
        local lerp = (Time.time - resetTime) / resetLerpDuration

        local position = client.localPlayer.character.gameObject.transform.position
        target = Vector3.Lerp(target, position, lerp)
        rotation.x = Mathf.LerpAngle(rotation.x, 0, lerp)
        rotation.y = Mathf.LerpAngle(rotation.y, 0, lerp)
        zoom = Mathf.Lerp(zoom, defaultZoom, lerp)

        if (lerp >= 1) then
            cameraMoveState = CameraMoveStateEnum.None
        end
    end

    if cameraMoveState == CameraMoveStateEnum.None or cameraMoveState == CameraMoveStateEnum.ManualControl then
        UpdateInertia()
    end

    UpdatePosition()
end
