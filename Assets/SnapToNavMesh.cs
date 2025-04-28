using UnityEditor;
using UnityEngine;
using UnityEngine.AI;

namespace Highrise.Studio
{
    public class SnapToNavMeshHelper
    {
        [MenuItem("GameObject/Snap to NavMesh")]
        static void SnapToNavMesh(MenuCommand command)
        {
            var gameObject = command.context as GameObject;
            if (gameObject == null)
                return;

            var transform = gameObject.transform;
            if (NavMesh.SamplePosition(transform.position, out var hit, 1000, NavMesh.AllAreas))
            {
                var targetPosition = hit.position;

                Bounds bounds = default;
                var hasBounds = false;
                foreach(var renderer in gameObject.GetComponentsInChildren<Renderer>())
                {
                    if (!hasBounds)
                    {
                        bounds = renderer.bounds;
                        hasBounds = true;
                    }
                    else
                    {
                        bounds.Encapsulate(renderer.bounds);
                    }
                }

                // if the object has renderers, nudge it up so all renderers are above the navmesh
                if (hasBounds)
                    targetPosition.y += transform.position.y - bounds.min.y;

                Undo.RecordObject(transform, "Snap to NavMesh");
                transform.position = targetPosition;
            }
        }

        [MenuItem("GameObject/Snap to NavMesh", true)]
        static bool SnapToNavMeshValidator()
        {
            return Selection.activeObject is GameObject;
        }
    }
}