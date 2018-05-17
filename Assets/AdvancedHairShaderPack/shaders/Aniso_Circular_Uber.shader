Shader "Advanced Hair Shader Pack/Aniso Circular Uber" 
{
	Properties 
	{
		_AnisoOffset ("Anisotropic Highlight Offset", Range(-1,1)) = 0.0
		_Gloss ( "Gloss Multiplier", float) = 128.0
		
		_MainTex ("Diffuse (RGB) Alpha (A)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		
		_NormalTex ("Normal Map", 2D) = "bump" {}
	  	_BumpPower ("Bump Power (from 3 to .01 ( 1 = use map)", float) = 1
		
		_SpecularPower("Specular Power", float) = 1.0
		_SpecularTex ("Specular (R) Gloss (G) Anisotropic Mask (B)", 2D) = "gray" {}		
		_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		
		_CombTex ("Comb Normal Map", 2D) = "bump" {}
		
		_Cutoff ("Alpha Cut-Off Threshold", float) = 0.95
		_BlendAlphaCut ("Blended Area Alpha Cut-Off Threshold", float) = 0
		
		_AOPower ("Ambient Occlusion Power", float) = 1
		_AOTex ("Ambient Occlussion Map", 2D) = "black" {}
		
		_RimMultiplier( "Rim Exponent", float) = 2
		_RimStrength("Rim Light Strength", float) = 0
		_RimColor("Rim Color", Color) = (1,1,1,1)
		
		_ColorMaskTex ("Color Mask (RGBA)", 2D) = "black" {}

		_ColorR("Color Tint R Mask Channel", Color) = (1, 1, 1, 1)  
		_ColorG("Color Tint G Mask Channel", Color) = (1, 1, 1, 1)
		_ColorB("Color Tint B Mask Channel", Color) = (1, 1, 1, 1)
		_ColorA("Color Tint A Mask Channel", Color) = (1, 1, 1, 1)
	}
	
	SubShader 
	{
		//change Transparent to Geometry to recieve shadows but will not be transparent with Environment!
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Blend Off
		Cull Back
		ZWrite on
		
		CGPROGRAM
		
		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		
		#pragma surface surf Hair
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed Gloss;
				fixed Alpha;
				fixed AnisoMask;
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 viewDir;
			};

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier, _AnisoOffset, _Gloss, _BlendAlphaCut;
			fixed4 _SpecularColor, _Color, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
			void surf (Input IN, inout SurfaceOutputHair o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = albedo;
				
				#if ANISO_AO_ON
					fixed3 ao = (1,1,1) - (tex2D(_AOTex, IN.uv_MainTex) * _AOPower);
					albedo.rgb *= ao.rgb;
				#endif 
				
				#if ANISO_COLORIZER_ON
					float4 colorizerMask = tex2D (_ColorMaskTex, IN.uv_MainTex);
					o.Albedo = lerp( albedo, _ColorR * albedo, colorizerMask.r);
					o.Albedo = lerp( o.Albedo, _ColorG * o.Albedo, colorizerMask.g);
					o.Albedo = lerp( o.Albedo, _ColorB * o.Albedo, colorizerMask.b);
					o.Albedo = lerp( o.Albedo, _ColorA * o.Albedo, colorizerMask.a); 
				#else 
					o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				#endif
				
				o.Alpha = albedo.a;
				clip ( o.Alpha - _Cutoff  );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r
							#if ANISO_AO_ON 
								* ao.rgb 
							#endif 
							;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;

				#if ANISO_BUMP_ON
					o.Normal = UnpackNormal( tex2D(_NormalTex, IN.uv_MainTex));
					o.Normal.z = o.Normal.z * _BumpPower; // use trick (change z & normalize) to make normal closer/further from original
					o.Normal = normalize(o.Normal);
	    		#endif
	    		
	    		#if ANISO_RIM_ON
			        fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
		        	o.Emission = _RimColor.rgb * _RimStrength * pow (rim, _RimMultiplier);
	    		#endif
			}
			
			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(s.Normal, lightDir));
				
				fixed HdotA = dot(s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				fixed4 c;
				c.rgb = diff * s.Albedo + (spec * _SpecularPower) * atten * 2 * _LightColor0.rgb * NdotL;
				c.a = s.Alpha; 
				return c;
			}
		ENDCG
		
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		ZWrite off
		
		CGPROGRAM
		
		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		
		#pragma surface surf Hair alpha
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed Gloss;
				fixed Alpha;
				fixed AnisoMask;
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 viewDir;
			};

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier, _AnisoOffset, _Gloss, _BlendAlphaCut;
			fixed4 _SpecularColor, _Color, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
			void surf (Input IN, inout SurfaceOutputHair o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = albedo;
				
				#if ANISO_AO_ON
					fixed3 ao = (1,1,1) - (tex2D(_AOTex, IN.uv_MainTex) * _AOPower);
					albedo.rgb *= ao.rgb;
				#endif 
				
				#if ANISO_COLORIZER_ON
					float4 colorizerMask = tex2D (_ColorMaskTex, IN.uv_MainTex);
					o.Albedo = lerp( albedo, _ColorR * albedo, colorizerMask.r);
					o.Albedo = lerp( o.Albedo, _ColorG * o.Albedo, colorizerMask.g);
					o.Albedo = lerp( o.Albedo, _ColorB * o.Albedo, colorizerMask.b);
					o.Albedo = lerp( o.Albedo, _ColorA * o.Albedo, colorizerMask.a); 
				#else 
					o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				#endif
				
				o.Alpha = albedo.a;
				clip ( _Cutoff  - o.Alpha );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r
							#if ANISO_AO_ON 
								* ao.rgb 
							#endif 
							;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;

				#if ANISO_BUMP_ON
					o.Normal = UnpackNormal( tex2D(_NormalTex, IN.uv_MainTex));
					o.Normal.z = o.Normal.z * _BumpPower; // use trick (change z & normalize) to make normal closer/further from original
					o.Normal = normalize(o.Normal);
	    		#endif
	    		
	    		#if ANISO_RIM_ON
			        fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
		        	o.Emission = _RimColor.rgb * _RimStrength * pow (rim, _RimMultiplier);
	    		#endif
			}

			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(s.Normal, lightDir));
				
				fixed HdotA = dot(s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				fixed4 c;
				c.rgb = diff * s.Albedo + (spec * _SpecularPower) * s.Alpha * atten * 2 * _LightColor0.rgb * NdotL;
				c.a = s.Alpha * step(_BlendAlphaCut, s.Alpha) ; 
				return c;
			}
		ENDCG
	}
	Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
	CustomEditor "CustomAnisoCircularUberInspector"
}