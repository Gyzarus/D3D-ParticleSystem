//=============================================================================
// Rain.fx by Frank Luna (C) 2011 All Rights Reserved.
//
// Rain particle system.  Particles are emitted directly in world space.
//=============================================================================


//***********************************************
// GLOBALS                                      *
//***********************************************

cbuffer cbPerFrame
{
	float3 gEyePosW;

	// for when the emit position/direction is varying
	float3 gEmitPosW;
	float3 gEmitDirW;

	float gGameTime;
	float gTimeStep;
	float4x4 gViewProj;
};

cbuffer cbFixed
{
	// Net constant acceleration used to accerlate the particles.
	//���ӵĺ㶨���ٶ�
	//xiaojun
	float3 gAccelW = { 0.0f, -29.8f, 0.0f };
};

// Array of textures for texturing the particles.
Texture2DArray gTexArray;

// Random texture used to generate random numbers in shaders.
Texture1D gRandomTex;

SamplerState samLinear
{
	Filter = MIN_MAG_MIP_LINEAR;
	AddressU = WRAP;
	AddressV = WRAP;
};

DepthStencilState DisableDepth
{
	DepthEnable = FALSE;
	DepthWriteMask = ZERO;
};

DepthStencilState NoDepthWrites
{
	DepthEnable = TRUE;
	DepthWriteMask = ZERO;
};
//���ģʽ����
BlendState AdditiveBlending
{
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = TRUE;
	SrcBlend = SRC_ALPHA;
	DestBlend = ONE;
	BlendOp = ADD;
	SrcBlendAlpha = ZERO;
	DestBlendAlpha = ZERO;
	BlendOpAlpha = ADD;
	RenderTargetWriteMask[0] = 0x0F;
};

//***********************************************
// HELPER FUNCTIONS                             *
//***********************************************
float3 RandUnitVec3(float offset)
{
	// Use game time plus offset to sample random texture.
	float u = (gGameTime + offset);

	// coordinates in [-1,1]
	float3 v = gRandomTex.SampleLevel(samLinear, u, 0).xyz;

		// project onto unit sphere
		return normalize(v);
}

float3 RandVec3(float offset)
{
	// Use game time plus offset to sample random texture.
	//xiaojun 	float u = (gGameTime + offset);
	float u = (gGameTime + offset);

	// coordinates in [-1,1]
	float3 v = gRandomTex.SampleLevel(samLinear, u, 0).xyz;

		//xiaojun return v;
		return normalize(v);
}

float3 RandVec3(float offset, int i)
{
	// Use game time plus offset to sample random texture.
	//xiaojun 	float u = (gGameTime + offset);
	float u = offset + 2;

	// coordinates in [-1,1]
	float3 v = gRandomTex.SampleLevel(samLinear, u, 0).xyz;

		//xiaojun return v;
		return v;
}
float RandVec(float offset)
{

	float u = offset + gGameTime;
	// coordinates in [-1,1]
	float v = gRandomTex.SampleLevel(samLinear, u, 0).x;

	return v;
}
//***********************************************
// STREAM-OUT TECH                              *
//***********************************************

#define PT_EMITTER 0
#define PT_FLARE 1

struct Particle
{
	float3 InitialPosW : POSITION;//λ��
	float3 InitialVelW : VELOCITY;//�ٶ�
	float2 SizeW       : SIZE;    //��С
	float Age : AGE;
	uint Type          : TYPE;
};

Particle StreamOutVS(Particle vin)
{
	return vin;
}

// The stream-out GS is just responsible for emitting 
// new particles and destroying old particles.  The logic
// programed here will generally vary from particle system
// to particle system, as the destroy/spawn rules will be 
// different.

// Stream-out GSֻ�����������Ӳ��ƻ������ӡ� �����̵��߼�ͨ��������ϵͳ�Ĳ�ͬ����ͬ����Ϊ�ƻ�/�������򽫻᲻ͬ��
[maxvertexcount(101)]
void StreamOutGS(point Particle gin[1],
	inout PointStream<Particle> ptStream)
{
	gin[0].Age += gTimeStep;

	if (gin[0].Type == PT_EMITTER)
	{
		// time to emit a new particle?
		// ��Ϊ���ӷ�����
		// ����0.002s,��������µ�����  
		if (gin[0].Age > 0.5f)
		{
			float3 vRandom3 = 40.0f*RandVec3(0.0f);
				for (int i = 0; i < 100; ++i)
				{
					// Spread rain drops out above the camera.
					//��������ɢ��
					float3 vRandom = float3(0.0f, 20.0f, 200.0f);

					float3 vRandom2 = 20.0f*RandVec3((float)i / 100.0f);
						//

						Particle p;
					//xiaojun p.InitialPosW = gEmitPosW.xyz + vRandom;
					p.InitialPosW = vRandom3 + vRandom;
					p.InitialPosW.y = 20.0f;
					//xiaojun p.InitialVelW = float3(0.0f, 0.0f, 0.0f);
					p.InitialVelW = vRandom2;
					p.SizeW = float2(1.0f, 1.0f);
					p.Age = 0.0f;
					p.Type = PT_FLARE;

					ptStream.Append(p);
				}

			// reset the time to emit
			// ���跢������ʱ�䣬�ȴ��´η���
			gin[0].Age = 0.0f;
		}

		// always keep emitters
		// ���Ǳ������ӷ�����
		ptStream.Append(gin[0]);
	}
	else
	{
		// Specify conditions to keep particle; this may vary from system to system.
		// ��Ϊ��ͨ���ӣ�һ��ʱ�䱣������
		//if( gin[0].Age <= 1.0f )
		//float ve = gin[0].InitialVelW.y + gAccelW.y*gin[0].Age;
		//if (ve>-3.0)
		if (gin[0].Age <= 2.5f )
			ptStream.Append(gin[0]);
	}
}

GeometryShader gsStreamOut = ConstructGSWithSO(
	CompileShader(gs_5_0, StreamOutGS()),
	"POSITION.xyz; VELOCITY.xyz; SIZE.xy; AGE.x; TYPE.x");

technique11 StreamOutTech
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, StreamOutVS()));
		SetGeometryShader(gsStreamOut);

		// disable pixel shader for stream-out only
		SetPixelShader(NULL);

		// we must also disable the depth buffer for stream-out only
		SetDepthStencilState(DisableDepth, 0);
	}
}

//***********************************************
// DRAW TECH                                    *
//***********************************************

struct VertexOut
{
	float3 PosW  : POSITION;
	float4 ColorW : COLOR;
	uint   Type  : TYPE;
};
// ��д������ɫ��
VertexOut DrawVS(Particle vin)
{
	VertexOut vout;

	float t = vin.Age;

	// constant acceleration equation
	// �㶨���ٶȼ�����빫ʽ
	vout.PosW = 0.5f*t*t*gAccelW + t*vin.InitialVelW + vin.InitialPosW;
	float opacity = 1.0f - smoothstep(0.0f, 1.0f, t / 2.5f);
	vout.ColorW = float4(0.3f, 1.0f, 0.5f, opacity);
	vout.Type = vin.Type;

	return vout;
}

struct GeoOut
{
	float4 PosH  : SV_Position;
	float4 ColorW : COLOR;
	float2 Tex   : TEXCOORD;
};
// The draw GS just expands points into lines.
// �������
// LineStream TriangleStream
[maxvertexcount(5)]
void DrawGS(point VertexOut gin[1],
	inout TriangleStream<GeoOut> lineStream)
{
	GeoOut output;
	float3 g_positions[4] =
	{
		float3(-1.0f, 1.0f, 0),
		float3(1.0f, 1.0f, 0),
		float3(-1.0f, -1.0f, 0),
		float3(1.0f, -1.0f, 0),
	};
	float2 g_texcoords[4] =
	{
		float2(0, 1),
		float2(1, 1),
		float2(0, 0),
		float2(1, 0),
	};
	for (int i = 0; i<4; i++)
	{
		float3 position = g_positions[i] ;
			position = position + gin[0].PosW;
		output.PosH = mul(float4(position, 1.0), gViewProj);

		output.ColorW = gin[0].ColorW;
		output.Tex = g_texcoords[i];
		lineStream.Append(output);
	}
}
// �����ŵ���
float4 DrawPS(GeoOut pin) : SV_TARGET
{
	return gTexArray.Sample(samLinear, float3(pin.Tex, 0))*pin.ColorW;
}

technique11 DrawTech
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, DrawVS()));
		SetGeometryShader(CompileShader(gs_5_0, DrawGS()));
		SetPixelShader(CompileShader(ps_5_0, DrawPS()));

		SetBlendState(AdditiveBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xffffffff);
		SetDepthStencilState(NoDepthWrites, 0);
	}
}