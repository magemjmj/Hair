/*
http://www.cgsoso.com/forum-211-1.html

CG搜搜 Unity3d 每日Unity3d插件免费更新 更有VIP资源！

CGSOSO 主打游戏开发，影视设计等CG资源素材。

插件如若商用，请务必官网购买！

daily assets update for try.

U should buy the asset from home store if u use it in your project!
*/

using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System.Linq;

//customization targets:
// direction ( vector or comb map)
// bump (normal + power) 
// Rim Lighting ( fresnel + exponent )
// 4 Channel Colorizer 
// fakey AO 

public class CustomAnisoUberInspector : MaterialEditor
{
	Material targetMat;
	string[] keyWords;

	bool somethingChanged = false;

	bool rim = false;
	bool bump = false;
	bool ao = false;
	bool useDirMap = false;
	bool useColorizerMap = false;
	bool isSkinned = false;

	public override void OnInspectorGUI ()
	{
		if (!isVisible)
			return;

		somethingChanged = false;

		// get the current keywords from the material
		targetMat = target as Material;
		keyWords = targetMat.shaderKeywords;

		//make all the checkmarks for each keyword
		EditorGUI.BeginChangeCheck ();
		bump = keyWords.Contains ("ANISO_BUMP_ON");
		bump = EditorGUILayout.Toggle ("Use Normal Map ?", bump);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;

		EditorGUI.BeginChangeCheck ();
		rim = keyWords.Contains ("ANISO_RIM_ON");
		rim = EditorGUILayout.Toggle ("Use Rim Light ?", rim);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;

		EditorGUI.BeginChangeCheck ();
		ao = keyWords.Contains ("ANISO_AO_ON");
		ao = EditorGUILayout.Toggle ("Use Ambient Occlussion Map ?", ao);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;

		EditorGUI.BeginChangeCheck ();
		useDirMap = keyWords.Contains ("ANISO_DIRECTION_MAP");
		useDirMap = EditorGUILayout.Toggle ("Use Direction(Comb) Map ?", useDirMap);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;

		EditorGUI.BeginChangeCheck ();
		useColorizerMap = keyWords.Contains ("ANISO_COLORIZER_ON");
		useColorizerMap = EditorGUILayout.Toggle ("Use 4 Channel Colorizer Map ?", useColorizerMap);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;

		EditorGUI.BeginChangeCheck ();
		isSkinned = keyWords.Contains ("ANISO_SKINNED_ON");
		isSkinned = EditorGUILayout.Toggle ("Skinned Mesh?", isSkinned);
		if (EditorGUI.EndChangeCheck ())
			somethingChanged = true;
        
		//if any of them changed, then rebuild the list
		if (somethingChanged) {
			List<string> keywords = new List<string> ();
			keywords.Add ((bump ? "ANISO_BUMP_ON" : "ANISO_BUMP_OFF"));
			keywords.Add ((rim ? "ANISO_RIM_ON" : "ANISO_RIM_OFF"));
			keywords.Add ((ao ? "ANISO_AO_ON" : "ANISO_AO_OFF"));
			keywords.Add ((useDirMap ? "ANISO_DIRECTION_MAP" : "ANISO_DIRECTION_VEC"));
			keywords.Add ((useColorizerMap ? "ANISO_COLORIZER_ON" : "ANISO_COLORIZER_OFF"));
			keywords.Add ((isSkinned ? "ANISO_SKINNED_ON" : "ANISO_SKINNED_OFF"));

			targetMat.shaderKeywords = keywords.ToArray ();
			EditorUtility.SetDirty (targetMat);
		}

		manualRenderOriginalMinusDisabled (targetMat.shaderKeywords);
	}

	void manualRenderOriginalMinusDisabled (string[] keywords)
	{
		serializedObject.Update ();
		var theShader = serializedObject.FindProperty ("m_Shader"); 
		if (isVisible && !theShader.hasMultipleDifferentValues && theShader.objectReferenceValue != null) {
			float controlSize = 64;
            
			EditorGUIUtility.labelWidth = Screen.width - controlSize - 20;
            
			EditorGUI.BeginChangeCheck ();
			Shader shader = theShader.objectReferenceValue as Shader;

			for (int i = 0; i < ShaderUtil.GetPropertyCount(shader); i++) {
				MaterialProperty matProp = GetMaterialProperty (new Object[]{targetMat}, ShaderUtil.GetPropertyName (shader, i));
             
				bool renderThisProp = true;
				if (!bump && (matProp.name == "_NormalTex" || matProp.name == "_BumpPower"))
					renderThisProp = false;

				if (!rim && (matProp.name == "_RimMultiplier" || matProp.name == "_RimStrength" || matProp.name == "_RimColor"))
					renderThisProp = false;

				if (!ao && (matProp.name == "_AOPower" || matProp.name == "_AOTex"))
					renderThisProp = false;

				if ((matProp.name == "_CombTex" && !useDirMap) || (matProp.name == "_AnisoDir" && useDirMap))
					renderThisProp = false;

				if (!useColorizerMap && (matProp.name == "_ColorMaskTex" || matProp.name == "_ColorR" 
					|| matProp.name == "_ColorG" || matProp.name == "_ColorB" || matProp.name == "_ColorA"))
					renderThisProp = false;
                
				if (renderThisProp)
					ShaderProperty (matProp, matProp.displayName);
			}
            
			if (EditorGUI.EndChangeCheck ())
				PropertiesChanged ();
		}
	}
}
