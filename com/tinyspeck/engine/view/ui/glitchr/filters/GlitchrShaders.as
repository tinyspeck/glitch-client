package com.tinyspeck.engine.view.ui.glitchr.filters {
	

	public class GlitchrShaders {
		
		[Embed("../../../../../../../assets/outline.pbj", mimeType="application/octet-stream")]
		public static const OutlineShader:Class;
		
		[Embed("../../../../../../../assets/historic.pbj", mimeType="application/octet-stream")]
		public static const HistoricShader:Class;
		
		[Embed("../../../../../../../assets/ChannelColorizer.pbj", mimeType="application/octet-stream")]
		public static const ChannelColorizerShader:Class;
		
		[Embed("../../../../../../../assets/noise.pbj", mimeType="application/octet-stream")]
		public static const NoiseShader:Class;
		
		[Embed("../../../../../../../assets/ColorSeparator.pbj", mimeType="application/octet-stream")]
		public static const ColorSeparatorShader:Class;
		
		[Embed("../../../../../../../assets/Curves.pbj", mimeType="application/octet-stream")]
		public static const CurvesShader:Class;
		
		[Embed("../../../../../../../assets/Dither.pbj", mimeType="application/octet-stream")]
		public static const DitherShader:Class;
	}
}