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

ParticleEffect* Effects::FireFX   = 0;
ParticleEffect* Effects::RainFX   = 0;
ParticleEffect* Effects::SnowFX = 0;
ParticleEffect* Effects::FireworksFX = 0;

void Effects::InitAll(ID3D11Device* device)
{
	SnowFX = new ParticleEffect(device, L"FX/Snow.fxo");
	FireFX = new ParticleEffect(device, L"FX/Fire.fxo");
	RainFX = new ParticleEffect(device, L"FX/Rain.fxo");
	FireworksFX = new ParticleEffect(device, L"FX/firework.fxo");
}

void Effects::DestroyAll()
{
	SafeDelete(SnowFX);
	SafeDelete(FireFX);
	SafeDelete(RainFX);
	SafeDelete(FireworksFX);
}

#pragma endregion