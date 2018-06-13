//***************************************************************************************
// 
//by Frank Luna (C) 2011 All Rights Reserved.
//
// Demonstrates GPU based particle systems.
//
// Controls:
//		Hold the left mouse button down and move the mouse to rotate.
//      Hold the right mouse button down to zoom in and out.
//
//***************************************************************************************
#include "d3dApp.h"
#include "MathHelper.h"
#include "LightHelper.h"
#include "Effects.h"
#include "Vertex.h"
#include "Camera.h"
#include "ParticleSystem.h"

class ParticlesApp : public D3DApp
{
public:
	ParticlesApp(HINSTANCE hInstance);
	~ParticlesApp();

	bool Init();
	void OnResize();
	void UpdateScene(float dt);
	void DrawScene(); 

	void OnMouseDown(WPARAM btnState, int x, int y);
	void OnMouseUp(WPARAM btnState, int x, int y);
	void OnMouseMove(WPARAM btnState, int x, int y);

private:
	ID3D11ShaderResourceView* mFlareTexSRV;
	ID3D11ShaderResourceView* mSnowTexSRV;
	ID3D11ShaderResourceView* mFireworkTexSRV;
	ID3D11ShaderResourceView* mRainTexSRV;
	ID3D11ShaderResourceView* mRandomTexSRV;

	ParticleSystem mFire;
	ParticleSystem mRain;
	ParticleSystem mSnow;
	ParticleSystem mFirework;

	INT32 mScenes;
	Camera mCam;

	POINT mLastMousePos;
};

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE prevInstance,
				   PSTR cmdLine, int showCmd)
{
	// 为调试启用运行时内存检查。
#if defined(DEBUG) | defined(_DEBUG)
	_CrtSetDbgFlag( _CRTDBG_ALLOC_MEM_DF | _CRTDBG_LEAK_CHECK_DF );
#endif

	ParticlesApp theApp(hInstance);
	
	if( !theApp.Init() )
		return 0;
	
	return theApp.Run();
}

ParticlesApp::ParticlesApp(HINSTANCE hInstance)
	: D3DApp(hInstance), mRandomTexSRV(0), mFlareTexSRV(0), mSnowTexSRV(0), mFireworkTexSRV(0), mRainTexSRV(0), mScenes(1)
{
	mMainWndCaption = L"ParticlesSystem 1:雨";
	mEnable4xMsaa = false;

	mLastMousePos.x = 0;
	mLastMousePos.y = 0;

	mCam.SetPosition(0.0f, 2.0f, 100.0f);
}

ParticlesApp::~ParticlesApp()
{
	md3dImmediateContext->ClearState();
	
	ReleaseCOM(mRandomTexSRV);
	ReleaseCOM(mSnowTexSRV)
	ReleaseCOM(mFireworkTexSRV);
	ReleaseCOM(mFlareTexSRV);
	ReleaseCOM(mRainTexSRV);


	Effects::DestroyAll();
	InputLayouts::DestroyAll();
}

bool ParticlesApp::Init()
{
	if(!D3DApp::Init())
		return false;

	// Must init Effects first since InputLayouts depend on shader signatures.
	// 效果文件初始化
	Effects::InitAll(md3dDevice);
	InputLayouts::InitAll(md3dDevice);
	mRandomTexSRV = d3dHelper::CreateRandomTexture1DSRV(md3dDevice);

	//材质加载
	std::vector<std::wstring> flares;
	flares.push_back(L"Textures\\flare.dds");
	mFlareTexSRV = d3dHelper::CreateTexture2DArraySRV(md3dDevice, md3dImmediateContext, flares);
	mFire.Init(md3dDevice, Effects::FireFX, mFlareTexSRV, mRandomTexSRV, 500); 
	mFire.SetEmitPos(XMFLOAT3(0.0f, 1.0f, 120.0f));

	std::vector<std::wstring> snowflake;
	snowflake.push_back(L"Textures\\snow.png");
	mSnowTexSRV = d3dHelper::CreateTexture2DArraySRV(md3dDevice, md3dImmediateContext, snowflake);
	mSnow.Init(md3dDevice, Effects::SnowFX, mSnowTexSRV, mRandomTexSRV, 10000);

	std::vector<std::wstring> firework;
	firework.push_back(L"Textures\\particle.dds");
	mFireworkTexSRV = d3dHelper::CreateTexture2DArraySRV(md3dDevice, md3dImmediateContext, firework);
	mFirework.Init(md3dDevice, Effects::FireworksFX, mFireworkTexSRV, mRandomTexSRV, 10000);

	std::vector<std::wstring> raindrops;
	raindrops.push_back(L"Textures\\raindrop.dds");
	mRainTexSRV = d3dHelper::CreateTexture2DArraySRV(md3dDevice, md3dImmediateContext, raindrops);
	//D3DX11CreateShaderResourceViewFromFileW(md3dDevice, str, NULL, NULL, &mRainTexSRV, NULL);
	mRain.Init(md3dDevice, Effects::RainFX, mRainTexSRV, mRandomTexSRV, 10000); 

	return true;
}

void ParticlesApp::OnResize()
{
	D3DApp::OnResize();

	mCam.SetLens(0.25f*MathHelper::Pi, AspectRatio(), 1.0f, 3000.0f);
}

void ParticlesApp::UpdateScene(float dt)
{
	//
	// Control the camera.
	//
	// 控制摄像头
	if( GetAsyncKeyState('W') & 0x8000 )
		mCam.Walk(10.0f*dt);

	if( GetAsyncKeyState('S') & 0x8000 )
		mCam.Walk(-10.0f*dt);

	if( GetAsyncKeyState('A') & 0x8000 )
		mCam.Strafe(-10.0f*dt);

	if( GetAsyncKeyState('D') & 0x8000 )
		mCam.Strafe(10.0f*dt);

	//
	// Reset particle systems.
	//
	if(GetAsyncKeyState('R') & 0x8000)
	{
		mScenes = 0;
	}
	if (GetAsyncKeyState('1') & 0x8000)
	{
		mScenes = 1;
		mFirework.Reset();

	}	
	if (GetAsyncKeyState('2') & 0x8000)
	{
		mScenes = 2;
		mSnow.Reset();
	}	
	if (GetAsyncKeyState('3') & 0x8000)
	{
		mScenes = 3;
		mFire.Reset();
	}	
	if (GetAsyncKeyState('4') & 0x8000)
	{
		mScenes = 4;
		mRain.Reset();
	}

	mFire.Update(dt, mTimer.TotalTime());
	mSnow.Update(dt, mTimer.TotalTime());
	mFirework.Update(dt, mTimer.TotalTime());
	mRain.Update(dt, mTimer.TotalTime());

	mCam.UpdateViewMatrix();
}

void ParticlesApp::DrawScene()
{
	//xiaojun md3dImmediateContext->ClearRenderTargetView(mRenderTargetView, reinterpret_cast<const float*>(&Colors::Silver));
	md3dImmediateContext->ClearRenderTargetView(mRenderTargetView, reinterpret_cast<const float*>(&Colors::Black)); //背景颜色
	md3dImmediateContext->ClearDepthStencilView(mDepthStencilView, D3D11_CLEAR_DEPTH | D3D11_CLEAR_STENCIL, 1.0f, 0);

	//md3dImmediateContext->IASetInputLayout(InputLayouts::Basic32);
	md3dImmediateContext->IASetPrimitiveTopology(D3D11_PRIMITIVE_TOPOLOGY_TRIANGLELIST);

	float blendFactor[] = { 0.0f, 0.0f, 0.0f, 0.0f };

	//?
	md3dImmediateContext->RSSetState(0);


	// Draw particle systems last so it is blended with scene.
	if (mScenes == 3)
	{
		mFire.SetEyePos(mCam.GetPosition());
		mFire.Draw(md3dImmediateContext, mCam);
		md3dImmediateContext->OMSetBlendState(0, blendFactor, 0xffffffff); // restore default
	}
	if (mScenes == 2)
	{
		mSnow.SetEyePos(mCam.GetPosition());
		mSnow.SetEmitPos(mCam.GetPosition());
		mSnow.Draw(md3dImmediateContext, mCam);
		md3dImmediateContext->OMSetBlendState(0, blendFactor, 0xffffffff); // restore default
	}
	if (mScenes == 1)
	{
		mFirework.SetEyePos(mCam.GetPosition());
		mFirework.SetEmitPos(mCam.GetPosition());
		mFirework.Draw(md3dImmediateContext, mCam);
		md3dImmediateContext->OMSetBlendState(0, blendFactor, 0xffffffff); // restore default
	}
	if (mScenes == 4)
	{
		mRain.SetEyePos(mCam.GetPosition());
		mRain.SetEmitPos(mCam.GetPosition());
		mRain.Draw(md3dImmediateContext, mCam);
	}
	//xiaojun md3dImmediateContext->OMSetBlendState(0, blendFactor, 0xffffffff); 

	// restore default states.
	md3dImmediateContext->RSSetState(0);
	md3dImmediateContext->OMSetDepthStencilState(0, 0);
	md3dImmediateContext->OMSetBlendState(0, blendFactor, 0xffffffff);

	HR(mSwapChain->Present(0, 0));
}

void ParticlesApp::OnMouseDown(WPARAM btnState, int x, int y)
{
	mLastMousePos.x = x;
	mLastMousePos.y = y;
	//该函数在属于当前线程的指定窗口里设置鼠标捕获
	//一旦窗口捕获了鼠标，所有鼠标输入都针对该窗口，无论光标是否在窗口的边界内。
	SetCapture(mhMainWnd);
}

void ParticlesApp::OnMouseUp(WPARAM btnState, int x, int y)
{
	ReleaseCapture();
}

void ParticlesApp::OnMouseMove(WPARAM btnState, int x, int y)
{
	if( (btnState & MK_LBUTTON) != 0 )
	{
		// Make each pixel correspond to a quarter of a degree.
		// 使每个像素对应四分之一度
		float dx = XMConvertToRadians(0.25f*static_cast<float>(x - mLastMousePos.x));
		float dy = XMConvertToRadians(0.25f*static_cast<float>(y - mLastMousePos.y));

		mCam.Pitch(dy);
		mCam.RotateY(dx);
	}

	mLastMousePos.x = x;
	mLastMousePos.y = y;
}
