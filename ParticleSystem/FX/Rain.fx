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
	//粒子的恒定加速度
	float3 gAccelW = { -1.0f, -9.8f, 0.0f };
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
	float u = (gGameTime + offset);

	// coordinates in [-1,1]
	float3 v = gRandomTex.SampleLevel(samLinear, u, 0).xyz;

		return v;
}

//***********************************************
// STREAM-OUT TECH                              *
//***********************************************

#define PT_EMITTER 0
#define PT_FLARE 1

struct Particle
{
	float3 InitialPosW : POSITION;//位置
	float3 InitialVelW : VELOCITY;//速度
	float2 SizeW       : SIZE;    //大小
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

// Stream-out GS只负责发射新粒子并破坏旧粒子。 这里编程的逻辑通按照粒子系统的不同而不同，因为破坏/重生规则将会不同。
[maxvertexcount(6)]
void StreamOutGS(point Particle gin[1],
	inout PointStream<Particle> ptStream)
{
	gin[0].Age += gTimeStep;

	if (gin[0].Type == PT_EMITTER)
	{
		// time to emit a new particle?
		// 若为粒子发射器
		// 经过0.002s,生成五个新的粒子  
		if (gin[0].Age > 0.002f)
		{
			float3 vRandom3 = 15.0f*RandVec3(0.0f);
				for (int i = 0; i < 5; ++i)
				{
					// Spread rain drops out above the camera.
					//将雨滴随机散开
					float3 vRandom = 35.0f*RandVec3((float)i / 5.0f);
						//离头顶一定距离
						vRandom.y = 20.0f;

					Particle p;
					p.InitialPosW = gEmitPosW.xyz + vRandom;
					p.InitialVelW = float3(0.0f, 0.0f, 0.0f);
					p.SizeW = float2(1.0f, 1.0f);
					p.Age = 0.0f;
					p.Type = PT_FLARE;

					ptStream.Append(p);
				}

			// reset the time to emit
			// 重设发射器的时间，等待下次发射
			gin[0].Age = 0.0f;
		}

		// always keep emitters
		// 总是保持粒子发射器
		ptStream.Append(gin[0]);
	}
	else
	{
		// Specify conditions to keep particle; this may vary from system to system.
		// 若为普通粒子，一定时间保持粒子
		if (gin[0].Age <= 3.0f)
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
	uint   Type  : TYPE;
};
// 编写定点着色器
VertexOut DrawVS(Particle vin)
{
	VertexOut vout;

	float t = vin.Age;

	// constant acceleration equation
	// 恒定加速度计算距离公式
	vout.PosW = 0.5f*t*t*gAccelW + t*vin.InitialVelW + vin.InitialPosW;

	vout.Type = vin.Type;

	return vout;
}

struct GeoOut
{
	float4 PosH  : SV_Position;
	float2 Tex   : TEXCOORD;
};

// The draw GS just expands points into lines.
// 拉伸雨滴
[maxvertexcount(2)]
// 编写几何着色器

void DrawGS(point VertexOut gin[1],
	inout LineStream<GeoOut> lineStream)
{
	// do not draw emitter particles.
	if (gin[0].Type != PT_EMITTER)
	{
		// Slant line in acceleration direction.
		float3 p0 = gin[0].PosW;

			float3 p1 = gin[0].PosW + 0.07f*gAccelW;
			//雨线起点
			GeoOut v0;
		v0.PosH = mul(float4(p0, 1.0f), gViewProj);
		v0.Tex = float2(0.0f, 0.0f);
		lineStream.Append(v0);
		//雨线终点
		GeoOut v1;
		v1.PosH = mul(float4(p1, 1.0f), gViewProj);
		v1.Tex = float2(1.0f, 1.0f);
		lineStream.Append(v1);
	}
}
// 像素着点器
float4 DrawPS(GeoOut pin) : SV_TARGET
{
	return gTexArray.Sample(samLinear, float3(pin.Tex, 0));
}

technique11 DrawTech
{
	pass P0
	{
		SetVertexShader(CompileShader(vs_5_0, DrawVS()));
		SetGeometryShader(CompileShader(gs_5_0, DrawGS()));
		SetPixelShader(CompileShader(ps_5_0, DrawPS()));

		SetDepthStencilState(NoDepthWrites, 0);
	}
}