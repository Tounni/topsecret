============================================================================
# README - Uso del Shader "RGBShaderCustom"
#  Creado por: @aex_savage_
* 
# Descripción:
*   Este shader genera un efecto de cambio de color RGB animado, con soporte para:
*     - Transparencia configurable.
*     - Renderizado en ambos lados o solo en una cara (personalizable).
*     - Emisión HDR que, combinada con post-procesamiento, activa el efecto Bloom.
*     - Modo de color seleccionable: colores aleatorios o cinco colores personalizados.
*     - Parámetros avanzados de ajuste visual (saturación, brillo y contraste).
*     - Soporte para texturas personalizadas.
 
# Licencia:
*   Este shader es libre de modificar y utilizar. Siente la libertad de adaptar y 
*   mejorar el código según las necesidades de tu proyecto.

# Instrucciones de uso:
* 
#   1. Creación del Material:
*      - Haz clic derecho en el Project Window y selecciona:
*          Create -> Material
*      - Asigna el shader creado (RGBShaderCustom) al material.
 
#   2. Aplicación del Material:
*      - Aplica el material a tu objeto, por ejemplo, un plano que represente una luz disco u otro objeto.
 
#   3. Configuración de Parámetros:
*      - _Speed: Controla la velocidad del cambio de color.
*      - _Alpha: Define la transparencia (rango de 0 a 1).
*      - _EmissionIntensity: Multiplica la intensidad de la emisión para lograr valores HDR.
*      - _CullingMode: Define si el objeto se renderiza por dentro, por fuera o en ambos lados.
*      - _BlendMode: Define el tipo de transparencia (opaco, cutout, transparente o aditivo).
*      - _Cutoff: Controla el nivel de corte alfa cuando se usa el modo "Cutout".
*      - _ColorMode: Permite elegir entre colores aleatorios o personalizados.
*      - _TransitionSpeed: Controla la velocidad de transición entre los colores.
*      - _Color1 - _Color5: Slots para definir hasta 5 colores personalizados.
*      - _Saturation: Ajusta la saturación de los colores.
*      - _Brightness: Ajusta el brillo de los colores.
*      - _Contrast: Ajusta el contraste de los colores.
*      - _MainTex: Permite aplicar una textura personalizada al material.
 
#   4. Activación del Bloom (opcional):
*      - Instala y configura el paquete de Post Processing (si aún no lo tienes).
*      - Añade un Post Process Volume global en la escena y habilita el efecto Bloom.
*      - Asegúrate de que la cámara tenga habilitado HDR para que se detecten los valores
*        brillantes generados por el shader.
 
# Notas adicionales:
*   - El shader ahora permite elegir entre colores aleatorios o personalizados.
*   - Se ha añadido compatibilidad con texturas para mayor versatilidad.
*   - Permite ajustes de saturación, brillo y contraste para mayor control visual.

# Modificaciones:
*   - Este shader es de libre uso y modificación. Cualquier cambio o mejora es bienvenido.

============================================================================
# README - Usage of "RGBShaderCustom"
#  Created by: @aex_savage_
* 
# Description:
*   This shader generates an animated RGB color-changing effect, with support for:
*     - Configurable transparency.
*     - Two-sided or single-face rendering (customizable).
*     - HDR emission that, combined with post-processing, activates the Bloom effect.
*     - Selectable color mode: random colors or five custom colors.
*     - Advanced visual adjustment parameters (saturation, brightness, and contrast).
*     - Support for custom textures.
 
# License:
*   This shader is free to modify and use. Feel free to adapt and improve the code
*   according to the needs of your project.

# Usage Instructions:
* 
#   1. Creating the Material:
*      - Right-click in the Project Window and select:
*          Create -> Material
*      - Assign the created shader (RGBShaderCustom) to the material.
 
#   2. Applying the Material:
*      - Apply the material to your object, for example, a plane representing a disco light or another object.
 
#   3. Configuring Parameters:
*      - _Speed: Controls the speed of the color change.
*      - _Alpha: Defines the transparency (range from 0 to 1).
*      - _EmissionIntensity: Multiplies the emission intensity to achieve HDR values.
*      - _CullingMode: Defines if the object is rendered inside, outside, or on both sides.
*      - _BlendMode: Defines the type of transparency (opaque, cutout, transparent, or additive).
*      - _Cutoff: Controls the alpha cut level when using "Cutout" mode.
*      - _ColorMode: Allows choosing between random or custom colors.
*      - _TransitionSpeed: Controls the speed of transition between colors.
*      - _Color1 - _Color5: Slots to define up to 5 custom colors.
*      - _Saturation: Adjusts the saturation of colors.
*      - _Brightness: Adjusts the brightness of colors.
*      - _Contrast: Adjusts the contrast of colors.
*      - _MainTex: Allows applying a custom texture to the material.
 
#   4. Activating Bloom (Optional):
*      - Install and configure the Post Processing package (if you haven't already).
*      - Add a global Post Process Volume to the scene and enable the Bloom effect.
*      - Ensure that the camera has HDR enabled so that the bright values generated by the shader are detected.
 
# Additional Notes:
*   - The shader now allows choosing between random or custom colors.
*   - Texture support has been added for greater versatility.
*   - Allows adjustments of saturation, brightness, and contrast for better visual control.

# Modifications:
*   - This shader is free for use and modification. Any changes or improvements are welcome.

============================================================================

