Shader "Advanced Hair Shader Pack/doublesided/Aniso Circular DoubleSided Correct" 
{
	Properties 
	{
		_MainTex ("Diffuse (RGB) Alpha (A)", 2D) = "white" {}
		_Color ("Main Color", Color) = (1,1,1,1)
		_SpecularTex ("Specular (R) Gloss (G) Anisotropic Mask (B)", 2D) = "gray" {}
		_SpecularMultiplier ("Specular Multiplier", float) = 1.0
		_SpecularColor ("Specular Color", Color) = (1,1,1,1)
		_AnisoOffset ("Anisotropic Highlight Offset", Range(-1,1)) = 0.0
		_Cutoff ("Alpha Cut-Off Threshold", float) = 0.9
		_Gloss ( "Gloss Multiplier", float) = 128.0
	}
	
	SubShader
	{	
		Tags {"Queue"="Geometry" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
		
		Blend Off
		Cull back
		ZWrite on
		
		CGPROGRAM
		#pragma surface surf Aniso
			
			struct SurfaceOutputAniso 
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
			};

			sampler2D _MainTex, _SpecularTex;
			float _AnisoOffset, _SpecularMultiplier, _Gloss, _Cutoff;
			fixed4 _SpecularColor, _Color;
			
			void surf (Input IN, inout SurfaceOutputAniso o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				o.Alpha = albedo.a;
				clip ( o.Alpha - _Cutoff  );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;
			}

			inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(s.Normal, lightDir));
				
				fixed HdotA = dot(s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				spec = spec * _SpecularMultiplier;
				
				fixed4 c;
				c.rgb = ((s.Albedo * _LightColor0.rgb * NdotL * _Color) + (_LightColor0.rgb * spec * _SpecularColor * NdotL)) * (atten * 2);
				c.a = s.Alpha;
				
				return c;
			}
		ENDCG
				
		Blend SrcAlpha OneMinusSrcAlpha
		Cull back
		ZWrite off
		
		CGPROGRAM
		#pragma surface surf Aniso
			
			struct SurfaceOutputAniso 
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
			};

			sampler2D _MainTex, _SpecularTex;
			float _AnisoOffset, _SpecularMultiplier, _Gloss, _Cutoff;
			fixed4 _SpecularColor, _Color;
			
			void surf (Input IN, inout SurfaceOutputAniso o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				o.Alpha = albedo.a;
				clip ( _Cutoff  - o.Alpha );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;
			}

			inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(s.Normal, lightDir));
				
				fixed HdotA = dot(s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				spec = spec * _SpecularMultiplier;
				
				fixed4 c;
				c.rgb = s.Alpha * ((s.Albedo * _LightColor0.rgb * NdotL * _Color) + (_LightColor0.rgb * spec * _SpecularColor * NdotL)) * (atten * 2);
				c.a = s.Alpha;
				return c;
			}
		ENDCG
		
		Blend Off
		Cull front
		ZWrite on
		
		CGPROGRAM
		#pragma surface surf Aniso
			
			struct SurfaceOutputAniso 
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
			};

			sampler2D _MainTex, _SpecularTex;
			float _AnisoOffset, _SpecularMultiplier, _Gloss, _Cutoff;
			fixed4 _SpecularColor, _Color;
			
			void surf (Input IN, inout SurfaceOutputAniso o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				o.Alpha = albedo.a;
				clip ( o.Alpha - _Cutoff  );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;
			}

			inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(-s.Normal, lightDir));
				
				fixed HdotA = dot(-s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(-s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				spec = spec * _SpecularMultiplier;
				
				fixed4 c;
				c.rgb = ((s.Albedo * _LightColor0.rgb * NdotL * _Color) + (_LightColor0.rgb * spec * _SpecularColor * NdotL)) * (atten * 2);
				c.a = s.Alpha;
				
				return c;
			}
		ENDCG
				
		Blend SrcAlpha OneMinusSrcAlpha
		Cull front
		ZWrite off
		
		CGPROGRAM
		#pragma surface surf Aniso
			
			struct SurfaceOutputAniso 
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
			};

			sampler2D _MainTex, _SpecularTex;
			float _AnisoOffset, _SpecularMultiplier, _Gloss, _Cutoff;
			fixed4 _SpecularColor, _Color;
			
			void surf (Input IN, inout SurfaceOutputAniso o)
			{
				fixed4 albedo = tex2D(_MainTex, IN.uv_MainTex);
				o.Albedo = lerp(albedo.rgb,albedo.rgb*_Color.rgb,0.5);
				o.Alpha = albedo.a;
				clip ( _Cutoff  - o.Alpha );
				fixed3 spec = tex2D(_SpecularTex, IN.uv_MainTex).rgb;
				o.Specular = spec.r;
				o.Gloss = spec.g;
				o.AnisoMask = spec.b;
			}

			inline fixed4 LightingAniso (SurfaceOutputAniso s, fixed3 lightDir, fixed3 viewDir, fixed atten)
			{
				fixed3 h = normalize(normalize(lightDir) + normalize(viewDir));
				float NdotL = saturate(dot(-s.Normal, lightDir));
				
				fixed HdotA = dot(-s.Normal, h);
				float aniso = max(0, sin(radians((HdotA + _AnisoOffset) * 180)));
				
				float spec = saturate(dot(-s.Normal, h));
				spec = saturate(pow(lerp(spec, aniso, s.AnisoMask), s.Gloss * _Gloss) * s.Specular);
				spec = spec * _SpecularMultiplier;
				
				fixed4 c;
				c.rgb = s.Alpha * ((s.Albedo * _LightColor0.rgb * NdotL * _Color) + (_LightColor0.rgb * spec * _SpecularColor * NdotL)) * (atten * 2);
				c.a = s.Alpha;
				return c;
			}
		ENDCG
	}
	FallBack "Transparent/Cutout/VertexLit"
}