//***************************************************************************************
// Effects.cpp by Frank Luna (C) 2011 All Rights Reserved.
//***************************************************************************************

#include "Effects.h"

#pragma region Effect
Effect::Effect(ID3D11Device* device, const std::wstring& filename)
	: mFX(0)
{
	std::ifstream fin(filename, std::ios::binary);

	fin.seekg(0, std::ios_base::end);
	int size = (int)fin.tellg();
	fin.seekg(0, std::ios_base::beg);
	std::vector<char> compiledShader(size);

	fin.read(&compiledShader[0], size);
	fin.close();
	// 从文件中创建Effect
	HR(D3DX11CreateEffectFromMemory(&compiledShader[0], size, 
		0, device, &mFX));
}

Effect::~Effect()
{
	ReleaseCOM(mFX);
}
#pragma endregion

#pragma region BasicEffect
BasicEffect::BasicEffect(ID3D11Device* device, const std::wstring& filename)
	: Effect(device, filename)
{
	Light1Tech    = mFX->GetTechniqueByName("Light1");

	WorldViewProj     = mFX->GetVariableByName("gWorldViewProj")->AsMatrix();
	World             = mFX->GetVariableByName("gWorld")->AsMatrix();
	WorldInvTranspose = mFX->GetVariableByName("gWorldInvTranspose")->AsMatrix();
	TexTransform      = mFX->GetVariableByName("gTexTransform")->AsMatrix();
	EyePosW           = mFX->GetVariableByName("gEyePosW")->AsVector();
	FogColor          = mFX->GetVariableByName("gFogColor")->AsVector();
	FogStart          = mFX->GetVariableByName("gFogStart")->AsScalar();
	FogRange          = mFX->GetVariableByName("gFogRange")->AsScalar();
	DirLights         = mFX->GetVariableByName("gDirLights");
	Mat               = mFX->GetVariableByName("gMaterial");
	DiffuseMap        = mFX->GetVariableByName("gDiffuseMap")->AsShaderResource();
	CubeMap           = mFX->GetVariableByName("gCubeMap")->AsShaderResource();
}

BasicEffect::~BasicEffect()
{
}
#pragma endregion

#pragma region ParticleEffect
ParticleEffect::ParticleEffect(ID3D11Device* device, const std::wstring& filename)
	: Effect(device, filename)
{
	StreamOutTech    = mFX->GetTechniqueByName("StreamOutTech");
	DrawTech         = mFX->GetTechniqueByName("DrawTech");

	ViewProj    = mFX->GetVariableByName("gViewProj")->AsMatrix();
	GameTime    = mFX->GetVariableByName("gGameTime")->AsScalar();
	TimeStep    = mFX->GetVariableByName("gTimeStep")->AsScalar();
	EyePosW     = mFX->GetVariableByName("gEyePosW")->AsVector();
	EmitPosW    = mFX->GetVariableByName("gEmitPosW")->AsVector();
	EmitDirW    = mFX->GetVariableByName("gEmitDirW")->AsVector();
	TexArray    = mFX->GetVariableByName("gTexArray")->AsShaderResource();
	RandomTex   = mFX->GetVariableByName("gRandomTex")->AsShaderResource();
}

ParticleEffect::~ParticleEffect()
{
}
#pragma endregion

#pragma region Effects

BasicEffect*   Effects::BasicFX   = 0;
ParticleEffect* Effects::FireFX   = 0;
ParticleEffect* Effects::RainFX   = 0;

void Effects::InitAll(ID3D11Device* device)
{
	BasicFX = new BasicEffect(device, L"FX/Basic.fxo");
	FireFX = new ParticleEffect(device, L"FX/Fire.fxo");
	RainFX = new ParticleEffect(device, L"FX/Rain.fxo");
}

void Effects::DestroyAll()
{
	SafeDelete(BasicFX);
	SafeDelete(FireFX);
	SafeDelete(RainFX);
}

#pragma endregion