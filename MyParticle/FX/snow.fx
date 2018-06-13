
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
	float3 gAccelW = {-1.0f, -9.8f, 0.0f};
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
	float Age          : AGE;
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

	if( gin[0].Type == PT_EMITTER )
	{	
		// time to emit a new particle?
		// 若为粒子发射器
		// 经过0.002s,生成五个新的粒子  
		if( gin[0].Age > 0.02f )
		{
			float3 vRandom3 = 15.0f*RandVec3(0.0f);
			for(int i = 0; i < 5; ++i) 
			{
				// Spread rain drops out above the camera.
				//将雨滴随机散开
				float3 vRandom = 35.0f*RandVec3((float)i/5.0f);
				//离头顶一定距离
				vRandom.y = 17.0f;
				
				Particle p;
				p.InitialPosW = gEmitPosW.xyz + vRandom;
				p.InitialVelW = float3(0.0f, 0.0f, 0.0f);

				if (i>2)
					p.InitialVelW = float3(-1.0f, 0.0f, 0.0f);
				p.SizeW       = float2(0.15f, 0.15f);
				p.Age         = 0.0f;
				p.Type        = PT_FLARE;
				
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
		if( gin[0].Age <= 5.0f )
			ptStream.Append(gin[0]);
	}		
}

GeometryShader gsStreamOut = ConstructGSWithSO( 
	CompileShader( gs_5_0, StreamOutGS() ), 
	"POSITION.xyz; VELOCITY.xyz; SIZE.xy; AGE.x; TYPE.x" );
	
technique11 StreamOutTech
{
    pass P0
    {
        SetVertexShader( CompileShader( vs_5_0, StreamOutVS() ) );
        SetGeometryShader( gsStreamOut );
        
        // disable pixel shader for stream-out only
        SetPixelShader(NULL);
        
        // we must also disable the depth buffer for stream-out only
        SetDepthStencilState( DisableDepth, 0 );
    }
}

//***********************************************
// DRAW TECH                                    *
//***********************************************

struct VertexOut
{
	float3 PosW  : POSITION;
	//xiaojun new
	float2 SizeW : SIZE;
	float4 Color : COLOR;//
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
	//xiaojun 
	vout.SizeW = vin.SizeW;
	vout.Color = float4(1.0f, 1.0f, 1.0f, 1.0f);//
	vout.Type = vin.Type;
	
	return vout;
}

struct GeoOut
{
	float4 PosH  : SV_Position;
	//xiaojun 
	float4 Color : COLOR;//
	float2 Tex   : TEXCOORD;
};

// The draw GS just expands points into lines.
// 拉伸雨滴
[maxvertexcount(5)]
void DrawGS(point VertexOut gin[1],
	inout TriangleStream<GeoOut> triStream)
{
	// do not draw emitter particles.
	if (gin[0].Type != PT_EMITTER)
	{
		//
		// Compute world matrix so that billboard faces the camera.
		//公告板效果计算
		float3 look = normalize(gEyePosW.xyz - gin[0].PosW);
		float3 right = normalize(cross(float3(0, 1, 0), look));
		float3 up = cross(look, right);
		//
		// Compute triangle strip vertices (quad) in world space.
		//根据中心顶点，计算三角带形式的四个角的顶点坐标
		float halfWidth = 0.5f*gin[0].SizeW.x;
		float halfHeight = 0.5f*gin[0].SizeW.y;

		float4 v[4];
		v[0] = float4(gin[0].PosW + halfWidth*right - halfHeight*up, 1.0f);
		v[1] = float4(gin[0].PosW + halfWidth*right + halfHeight*up, 1.0f);
		v[2] = float4(gin[0].PosW - halfWidth*right - halfHeight*up, 1.0f);
		v[3] = float4(gin[0].PosW - halfWidth*right + halfHeight*up, 1.0f);
		float2 gQuadTexC[4] =
		{
			float2(0.0f, 1.0f),
			float2(1.0f, 1.0f),
			float2(0.0f, 0.0f),
			float2(1.0f, 0.0f)
		};
		//
		// Transform quad vertices to world space and output 
		// them as a triangle strip.
		// 转换四角顶点到世界坐标并且输出
		GeoOut gout;
		[unroll]
		for (int i = 0; i < 4; ++i)
		{
			gout.PosH = mul(v[i], gViewProj); //这里不需要世界投影，因为在应用程序阶段产生了世界坐标。保存了齐次空间坐标。
			gout.Tex = gQuadTexC[i];
			gout.Color = gin[0].Color;
			triStream.Append(gout);
		}
	}
}
// 像素着点器
float4 DrawPS(GeoOut pin) : SV_TARGET
{
	//xiaojun return gTexArray.Sample(samLinear, float3(pin.Tex, 0));
	return gTexArray.Sample(samLinear, float3(pin.Tex, 0))*pin.Color; 
}

technique11 DrawTech
{
    pass P0
    {
        SetVertexShader(   CompileShader( vs_5_0, DrawVS() ) );
        SetGeometryShader( CompileShader( gs_5_0, DrawGS() ) );
        SetPixelShader(    CompileShader( ps_5_0, DrawPS() ) );

		SetBlendState(AdditiveBlending, float4(0.0f, 0.0f, 0.0f, 0.0f), 0xffffffff);
        SetDepthStencilState( NoDepthWrites, 0 );
    }
}