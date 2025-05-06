import 'package:flutter/material.dart';
import 'package:model_viewer_plus/model_viewer_plus.dart';

class Car3DViewer extends StatelessWidget {
  final String modelUrl;
  final double? width;
  final double? height;

  const Car3DViewer({
    super.key,
    required this.modelUrl,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? MediaQuery.of(context).size.width,
      height: height ?? MediaQuery.of(context).size.height * 0.4,
      child: ModelViewer(
        src: modelUrl,
        alt: "3D Car Model",
        ar: true,
        autoRotate: true,
        cameraControls: true,
        backgroundColor: Colors.transparent,
        disableZoom: false,
        shadowIntensity: 1,
        shadowSoftness: 1,
        exposure: 1,
        environmentImage: 'neutral',
        minCameraOrbit: 'auto auto 10%',
        maxCameraOrbit: 'auto auto 100%',
        minFieldOfView: '30deg',
        maxFieldOfView: '90deg',
        interactionPrompt: InteractionPrompt.auto,
        interactionPromptStyle: InteractionPromptStyle.basic,
        loading: Loading.eager,
        reveal: Reveal.interaction,
        touchAction: TouchAction.panY,
        cameraTarget: '0 0 0',
        cameraOrbit: '0 75deg 105%',
        fieldOfView: '45deg',
        interpolationDecay: 200,
        rotationPerSecond: '30deg',
        orientation: '0 0 0',
        scale: '1 1 1',
        skyboxImage: 'neutral',
        variantName: '',
        // Removed unsupported 'onModelError' parameter
      ),
    );
  }
}
