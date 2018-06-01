#include <windows.h>
#include <D3dx9math.h>
#include "d3dApp.h"
#include "ParticleSystem.h"
#include "Effects.h"

class ParticlesApp : public D3DApp
{
public:
	ParticlesApp(HINSTANCE hInstance);
	~ParticlesApp();

	bool Init();
	void UpdateScene(float dt);
	void DrawScene();

	void OnMouseDown(WPARAM btnState, int x, int y);
	void OnMouseUp(WPARAM btnState, int x, int y);
	void OnMouseMove(WPARAM btnState, int x, int y);

private:
	//��ɫ����Դ��ͼ�ӿ�ָ����ɫ������Ⱦ�����п��Է��ʵ�����Դ,��ɫ����Դһ�����һ��������������һ������������һ������
	ID3D11ShaderResourceView* mRainTexSRV;
	ID3D11ShaderResourceView* mRandomTexSRV;

	ParticleSystem mRain;
};

int WINAPI WinMain(HINSTANCE hInstance, HINSTANCE prevInstance,
	PSTR cmdLine, int showCmd)
{
	ParticlesApp theApp(hInstance);

	if (!theApp.Init())
		return 0;

	return theApp.Run();
}

ParticlesApp::ParticlesApp(HINSTANCE hInstance)
	: D3DApp(hInstance)
{
	mMainWndCaption = L"ParticlesSystem";
	mEnable4xMsaa = false;

}


ParticlesApp::~ParticlesApp()
{
	md3dImmediateContext->ClearState();
	Effects::DestroyAll();
}


bool ParticlesApp::Init()
{
	if (!D3DApp::Init())
		return false;
	Effects::InitAll(md3dDevice);
	return true;
}


void ParticlesApp::UpdateScene(float dt)
{

}


void ParticlesApp::DrawScene()
{
	mSwapChain->Present(0, 0);
}

void ParticlesApp::OnMouseDown(WPARAM btnState, int x, int y)
{
	SetCapture(mhMainWnd);
}

void ParticlesApp::OnMouseUp(WPARAM btnState, int x, int y)
{
	ReleaseCapture();
}

void ParticlesApp::OnMouseMove(WPARAM btnState, int x, int y)
{
	if ((btnState & MK_LBUTTON) != 0)
	{
	}

}
