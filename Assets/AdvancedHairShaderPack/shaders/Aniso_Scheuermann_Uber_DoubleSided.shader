// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Advanced Hair Shader Pack/Aniso Scheuermann Uber Double Sided" 
{
	Properties 
	{
		_MainTex ("Diffuse (RGB) Alpha (A)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		
		_NormalTex ("Normal Map", 2D) = "bump" {}
	  	_BumpPower ("Bump Power (from 3 to .01 ( 1 = use map)", float) = 1
		
		_SpecularPower("Specular Power", float) = 1.0
		_SpecularTex ("Specular (R) Spec Shift (G) Noise (B)", 2D) = "gray" {}
		
		_SpecularMultiplier ("Specular Multiplier (exponent power of 2)", float) = 1.0
		_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		
		_SpecularMultiplier2 ("Secondary Specular Multiplier (exponent power of 2)", float) = 1.0
		_SpecularColor2 ("Secondary Specular Color", Color) = (1,1,1,1)
		
		_PrimaryShift ( "Specular Primary Shift", float) = .5
		_SecondaryShift ( "Specular Secondary Shift", float) = .7
		
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
		Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}

		Blend Off
		Cull Front
		ZWrite on
		
		CGPROGRAM

		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_DIRECTION_VEC ANISO_DIRECTION_MAP
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		#pragma shader_feature ANISO_SKINNED_OFF ANISO_SKINNED_ON
		
		#pragma surface surf Hair vertex:vert
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed SpecShift;
				fixed Alpha;
				fixed SpecMask;
				
				half3 tangent_input; 
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 tangent_input;
				float3 viewDir;
			};
			
			void vert(inout appdata_full i, out Input o)
			{	
				UNITY_INITIALIZE_OUTPUT(Input, o);	
			 	#if ANISO_SKINNED_ON
			 		o.tangent_input = normalize( mul( unity_ObjectToWorld, float4( i.tangent.xyz, 0.0 ) ).xyz );
				#else
					o.tangent_input = i.tangent.xyz ;
				#endif 
			}

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _SpecularMultiplier, _SpecularMultiplier2, _PrimaryShift, _SecondaryShift, 
			      _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier;
			fixed4 _SpecularColor, _Color, _SpecularColor2, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
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
				o.SpecShift = spec.g;
				o.SpecMask = spec.b;	
				
				#if ANISO_DIRECTION_MAP
					o.tangent_input = UnpackNormal( tex2D(_CombTex, IN.uv_MainTex));
				#else
					o.tangent_input = IN.tangent_input;
				#endif

				#if ANISO_BUMP_ON
					o.Normal = UnpackNormal( tex2D(_NormalTex, IN.uv_MainTex));
					o.Normal.z = o.Normal.z * _BumpPower; // use trick (change z & normalize) to make normal closer/further from original
					o.Normal = -normalize(o.Normal);
	    		#endif
	    		
	    		#if ANISO_RIM_ON
			        fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
		        	o.Emission = _RimColor.rgb * _RimStrength * pow (rim, _RimMultiplier);
	    		#endif
			}
			
			half3 ShiftTangent ( half3 T, half3 N, float shift)
			{
				half3 shiftedT = T+ shift * N;
				return normalize( shiftedT);
			}
			
			float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
			{
				half3 H = normalize ( L + V );
				float dotTH = dot ( T, H );
				float sinTH = sqrt ( 1 - dotTH * dotTH);
				float dirAtten = smoothstep( -1, 0, dotTH );
				return dirAtten * pow(sinTH, exponent);
			}

			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				float NdotL = saturate(dot(s.Normal, lightDir));
			
				float shiftTex = s.SpecShift - .5;
				half3 T = -normalize(cross( s.Normal, s.tangent_input));
				
				half3 t1 = ShiftTangent ( T, s.Normal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, s.Normal, _SecondaryShift + shiftTex );
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, viewDir, lightDir, _SpecularMultiplier);
				spec = spec +  _SpecularColor2 * s.SpecMask * StrandSpecular ( t2, viewDir, lightDir, _SpecularMultiplier2) ;
				
				fixed4 c;
				c.rgb = ((s.Albedo * diff ) + (s.Specular * spec * _SpecularPower)) * _LightColor0.rgb * (atten*2) * NdotL;
				c.a = s.Alpha; 
				return c;
			}
		ENDCG
		
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Front
		ZWrite off
		
		CGPROGRAM

		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_DIRECTION_VEC ANISO_DIRECTION_MAP
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		#pragma shader_feature ANISO_SKINNED_OFF ANISO_SKINNED_ON
		
		#pragma surface surf Hair vertex:vert alpha
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed SpecShift;
				fixed Alpha;
				fixed SpecMask;
				
				half3 tangent_input; 
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 tangent_input;
				float3 viewDir;
			};
			
			void vert(inout appdata_full i, out Input o)
			{	
				UNITY_INITIALIZE_OUTPUT(Input, o);
			 	#if ANISO_SKINNED_ON
			 		o.tangent_input = normalize( mul( unity_ObjectToWorld, float4( i.tangent.xyz, 0.0 ) ).xyz );
				#else
					o.tangent_input = i.tangent.xyz ;
				#endif 
			}

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _SpecularMultiplier, _SpecularMultiplier2, _PrimaryShift, _SecondaryShift, 
			      _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier, _BlendAlphaCut;
			fixed4 _SpecularColor, _Color, _SpecularColor2, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
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
				o.SpecShift = spec.g;
				o.SpecMask = spec.b;	
				
				#if ANISO_DIRECTION_MAP
					o.tangent_input = UnpackNormal( tex2D(_CombTex, IN.uv_MainTex));
				#else
					o.tangent_input = IN.tangent_input;
				#endif

				#if ANISO_BUMP_ON
				    o.Normal = UnpackNormal( tex2D(_NormalTex, IN.uv_MainTex));
					o.Normal.z = o.Normal.z * _BumpPower; // use trick (change z & normalize) to make normal closer/further from original
					o.Normal = -normalize(o.Normal);
	    		#endif

	    		#if ANISO_RIM_ON
			        fixed rim = 1.0 - saturate(dot (normalize(IN.viewDir), o.Normal));
		        	o.Emission = _RimColor.rgb * _RimStrength * pow (rim, _RimMultiplier);
	    		#endif
			}
			
			half3 ShiftTangent ( half3 T, half3 N, float shift)
			{
				half3 shiftedT = T+ shift * N;
				return normalize( shiftedT);
			}
			
			float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
			{
				half3 H = normalize ( L + V );
				float dotTH = dot ( T, H );
				float sinTH = sqrt ( 1 - dotTH * dotTH);
				float dirAtten = smoothstep( -1, 0, dotTH );
				return dirAtten * pow(sinTH, exponent);
			}

			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				float NdotL = saturate(dot(s.Normal, lightDir));
			
				float shiftTex = s.SpecShift - .5;
				half3 T = -normalize(cross( s.Normal, s.tangent_input));
				
				half3 t1 = ShiftTangent ( T, s.Normal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, s.Normal, _SecondaryShift + shiftTex );
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, viewDir, lightDir, _SpecularMultiplier);
				spec = spec +  _SpecularColor2 * s.SpecMask * StrandSpecular ( t2, viewDir, lightDir, _SpecularMultiplier2) ;

				fixed4 c;				
				c.rgb = ((s.Albedo * diff ) + (s.Specular * spec * _SpecularPower)) * _LightColor0.rgb * s.Alpha * (atten*2) * NdotL;
				c.a = s.Alpha * step(_BlendAlphaCut, s.Alpha) ; 
				return c;
			}
		ENDCG
		
		Blend Off
		Cull Back
		ZWrite on
		
		CGPROGRAM

		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_DIRECTION_VEC ANISO_DIRECTION_MAP
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		#pragma shader_feature ANISO_SKINNED_OFF ANISO_SKINNED_ON
		
		#pragma surface surf Hair vertex:vert
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed SpecShift;
				fixed Alpha;
				fixed SpecMask;
				
				half3 tangent_input; 
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 tangent_input;
				float3 viewDir;
			};
			
			void vert(inout appdata_full i, out Input o)
			{	
				UNITY_INITIALIZE_OUTPUT(Input, o);	
			 	#if ANISO_SKINNED_ON
			 		o.tangent_input = normalize( mul( unity_ObjectToWorld, float4( i.tangent.xyz, 0.0 ) ).xyz );
				#else
					o.tangent_input = i.tangent.xyz ;
				#endif 
			}

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _SpecularMultiplier, _SpecularMultiplier2, _PrimaryShift, _SecondaryShift, 
			      _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier;
			fixed4 _SpecularColor, _Color, _SpecularColor2, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
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
				o.SpecShift = spec.g;
				o.SpecMask = spec.b;	
				
				#if ANISO_DIRECTION_MAP
					o.tangent_input = UnpackNormal( tex2D(_CombTex, IN.uv_MainTex));
				#else
					o.tangent_input = IN.tangent_input;
				#endif

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
			
			half3 ShiftTangent ( half3 T, half3 N, float shift)
			{
				half3 shiftedT = T+ shift * N;
				return normalize( shiftedT);
			}
			
			float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
			{
				half3 H = normalize ( L + V );
				float dotTH = dot ( T, H );
				float sinTH = sqrt ( 1 - dotTH * dotTH);
				float dirAtten = smoothstep( -1, 0, dotTH );
				return dirAtten * pow(sinTH, exponent);
			}

			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				float NdotL = saturate(dot(s.Normal, lightDir));
			
				float shiftTex = s.SpecShift - .5;
				half3 T = -normalize(cross( s.Normal, s.tangent_input));
				
				half3 t1 = ShiftTangent ( T, s.Normal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, s.Normal, _SecondaryShift + shiftTex );
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, viewDir, lightDir, _SpecularMultiplier);
				spec = spec +  _SpecularColor2 * s.SpecMask * StrandSpecular ( t2, viewDir, lightDir, _SpecularMultiplier2) ;
				
				fixed4 c;
				c.rgb = ((s.Albedo * diff ) + (s.Specular * spec * _SpecularPower)) * _LightColor0.rgb * (atten*2) * NdotL;
				c.a = s.Alpha; 
				return c;
			}
		ENDCG
		
		Blend SrcAlpha OneMinusSrcAlpha
		Cull Back
		ZWrite off
		
		CGPROGRAM

		#pragma shader_feature ANISO_BUMP_OFF ANISO_BUMP_ON
		#pragma shader_feature ANISO_DIRECTION_VEC ANISO_DIRECTION_MAP
		#pragma shader_feature ANISO_RIM_OFF ANISO_RIM_ON
		#pragma shader_feature ANISO_AO_OFF ANISO_AO_ON
		#pragma shader_feature ANISO_COLORIZER_OFF ANISO_COLORIZER_ON
		#pragma shader_feature ANISO_SKINNED_OFF ANISO_SKINNED_ON
		
		#pragma surface surf Hair vertex:vert alpha
		#pragma target 3.0
		
			struct SurfaceOutputHair 
			{
				fixed3 Albedo;
				fixed3 Normal;
				fixed3 Emission;
				half Specular;
				fixed SpecShift;
				fixed Alpha;
				fixed SpecMask;
				
				half3 tangent_input; 
			};
					
			struct Input
			{
				float2 uv_MainTex;
				float3 tangent_input;
				float3 viewDir;
			};
			
			void vert(inout appdata_full i, out Input o)
			{	
				UNITY_INITIALIZE_OUTPUT(Input, o);
			 	#if ANISO_SKINNED_ON
			 		o.tangent_input = normalize( mul( unity_ObjectToWorld, float4( i.tangent.xyz, 0.0 ) ).xyz );
				#else
					o.tangent_input = i.tangent.xyz ;
				#endif 
			}

			sampler2D _MainTex, _SpecularTex, _NormalTex, _CombTex, _AOTex, _ColorMaskTex;
			float _SpecularMultiplier, _SpecularMultiplier2, _PrimaryShift, _SecondaryShift, 
			      _Cutoff, _SpecularPower, _BumpPower, _AOPower, _RimStrength, _RimMultiplier, _BlendAlphaCut;
			fixed4 _SpecularColor, _Color, _SpecularColor2, _ColorR, _ColorG, _ColorB, _ColorA, _RimColor;
			
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
				o.SpecShift = spec.g;
				o.SpecMask = spec.b;	
				
				#if ANISO_DIRECTION_MAP
					o.tangent_input = UnpackNormal( tex2D(_CombTex, IN.uv_MainTex));
				#else
					o.tangent_input = IN.tangent_input;
				#endif

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
			
			half3 ShiftTangent ( half3 T, half3 N, float shift)
			{
				half3 shiftedT = T+ shift * N;
				return normalize( shiftedT);
			}
			
			float StrandSpecular ( half3 T, half3 V, half3 L, float exponent)
			{
				half3 H = normalize ( L + V );
				float dotTH = dot ( T, H );
				float sinTH = sqrt ( 1 - dotTH * dotTH);
				float dirAtten = smoothstep( -1, 0, dotTH );
				return dirAtten * pow(sinTH, exponent);
			}

			inline fixed4 LightingHair (SurfaceOutputHair s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				float NdotL = saturate(dot(s.Normal, lightDir));
			
				float shiftTex = s.SpecShift - .5;
				half3 T = -normalize(cross( s.Normal, s.tangent_input));
				
				half3 t1 = ShiftTangent ( T, s.Normal, _PrimaryShift + shiftTex );
				half3 t2 = ShiftTangent ( T, s.Normal, _SecondaryShift + shiftTex );
				
				half3 diff = saturate ( lerp ( .25, 1, NdotL));
				diff = diff * _Color ;
				
				half3 spec =  _SpecularColor * StrandSpecular(t1, viewDir, lightDir, _SpecularMultiplier);
				spec = spec +  _SpecularColor2 * s.SpecMask * StrandSpecular ( t2, viewDir, lightDir, _SpecularMultiplier2) ;
				
				fixed4 c;
				c.rgb = ((s.Albedo * diff ) + (s.Specular * spec * _SpecularPower)) * _LightColor0.rgb * s.Alpha * (atten*2) * NdotL;
				c.a = s.Alpha * step(_BlendAlphaCut, s.Alpha) ; 
				return c;
			}
		ENDCG
	}
	Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
	CustomEditor "CustomAnisoUberInspector"
}