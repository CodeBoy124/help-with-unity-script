Shader "Custom/World_Shader"
{
    Properties
    {
        _Height ("Height", Float) = 2.0

        _Scale ("Scale", Float) = 3.0

        _ForestHeight ("Forest height", Float) = 0.5
        _StoneHeight ("Stone height", Float) = 0.7

        _Seed ("Seed", Float) = 7383.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "DisableBatching" = "True"}
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows vertex:vert addshadow

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        struct Input
        {
            float2 uv_MainTex;
            float3 world_position_pass;
        };

        float _ForestHeight;
        float _StoneHeight;

        float _Height;

        float _Scale;

        float _Seed;

        float frac2(float n1){
            float n = abs(n1);
            return n - floor(n);
        }

        float rand(float2 myVector)  {
            return frac2(sin( dot(myVector ,float2(12.9898,78.233) )) * _Seed*1000.0+364.0);
        }

        float2 randVecAt(float x, float y){
            float choice = rand(float2(x, y));
            if(choice < 0.25){
                return float2(-1.0, -1.0);
            }else if(choice < 0.5){
                return float2(1.0, -1.0);
            }else if(choice < 0.75){
                return float2(1.0, 1.0);
            }else{
                return float2(-1.0, 1.0);
            }
        }

        float cosInterp(float n){
            return (cos(n*3.141592653589793238462)+1.0)/2.0;
        }

        float2 Distance(float2 v1, float2 v2){
            return v2.xy - v1.xy;
        }

        float PerlinNoise(float x, float y){
                                                                 // X, Y
            float2 vec_random_0 = randVecAt(floor(x), floor(y)); // 0, 0
            float2 vec_random_1 = randVecAt(ceil(x), floor(y));  // 1, 0
            float2 vec_random_2 = randVecAt(ceil(x), ceil(y));   // 1, 1
            float2 vec_random_3 = randVecAt(floor(x), ceil(y));  // 0, 1
            
                                                                                     // X, Y
            float2 vec_dist_0 = Distance(float2(floor(x), floor(y)), float2(x, y));  // 0, 0
            float2 vec_dist_1 = Distance(float2(ceil(x), floor(y)), float2(x, y));   // 1, 0
            float2 vec_dist_2 = Distance(float2(ceil(x), ceil(y)), float2(x, y));    // 1, 1
            float2 vec_dist_3 = Distance(float2(floor(x), ceil(y)), float2(x, y));   // 0, 1
            
            float vec_dot_0 = dot(vec_random_0, vec_dist_0);
            float vec_dot_1 = dot(vec_random_1, vec_dist_1);
            float vec_dot_2 = dot(vec_random_2, vec_dist_2);
            float vec_dot_3 = dot(vec_random_3, vec_dist_3);
            
            float x10 = x - floor(x); // x10 is between 0 and 1
            float y10 = y - floor(y); // y10 is between 0 and 1
            
            // topleft && topright
            float upInterpolate = (vec_dot_0*cosInterp(x10))+(vec_dot_1*(1.0-cosInterp(x10)));
            
            // bottomleft && bottomright
            float downInterpolate = (vec_dot_3*cosInterp(x10))+(vec_dot_2*(1.0-cosInterp(x10)));

            float final = (upInterpolate*cosInterp(y10))+(downInterpolate*(1.0-cosInterp(y10)));
            return final;
        }

        float HeightFunc(float posX, float posY){
            float posX2 = -posX-3.0;
            float posY2 = posY-3.0;
            return PerlinNoise(posX2, posY2) + ((posX2+posY2) / 5.0);
        }

        float getHeightValue(float2 pos){
            float2 newPos = float2((pos.x + 10.0) / 20.0, (pos.y + 10.0) / 20.0);
            return HeightFunc(newPos.x*_Scale, newPos.y*_Scale)*_Height;
        }

        void vert (inout appdata_full v, out Input o)
        {
            float3 worldVec = mul(unity_ObjectToWorld, v.vertex).xyz;
            float oldWorldHeight = worldVec.y;
            float3 difWorldVec = worldVec;
            worldVec = float3(floor(worldVec.x), worldVec.y, floor(worldVec.z));
            difWorldVec = difWorldVec - worldVec;

            float3 v0 = worldVec;
            float3 v1 = worldVec + float3(0.1, 0.0, 0.0);
            float3 v2 = worldVec + float3(0.0, 0.0, 0.1);

            v0.y = getHeightValue(v0.xz);
            v1.y = getHeightValue(v1.xz);
            v2.y = getHeightValue(v2.xz);

            v.vertex.y += floor(getHeightValue(worldVec.xz));
            v.vertex.y -= oldWorldHeight;
            v.vertex.x -= difWorldVec.x;
            v.vertex.z -= difWorldVec.z;

            UNITY_INITIALIZE_OUTPUT(Input, o);
            o.world_position_pass = worldVec;
        }






        // all not so important stuff, because it's just for the albedo coloring and the normals wich both work fine

        float dif(float a, float b){
            return abs(a - b);
        }

        float2 getFirstNormal(float a, float b){
            if(dif(a, b) < 0.2){
                return float2(0.0, 1.0);
            }else if(a > b){
                return float2(1.0, 1.0);
            }else{
                return float2(-1.0, 1.0);
            }
        }

        float modP(float v){
            return v - floor(v);
        }

        float3 getNormal(float2 worldPosit){
            float v0 = floor(getHeightValue(float2(floor(worldPosit.x), floor(worldPosit.y)))); // 0, 0
            float v1 = floor(getHeightValue(float2(ceil(worldPosit.x), floor(worldPosit.y))));  // 1, 0
            float v2 = floor(getHeightValue(float2(floor(worldPosit.x), ceil(worldPosit.y))));  // 0, 1

            float3 p1 = float3(floor(worldPosit.x), floor(worldPosit.y), v0);
            float3 p2 = float3(ceil(worldPosit.x), floor(worldPosit.y), v1);
            float3 p3 = float3(floor(worldPosit.x), ceil(worldPosit.y), v2);

            return normalize(cross(p2-p1, p3-p1));
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            float resFromNoise = getHeightValue(IN.world_position_pass.xz);
            float res2FromNoise = PerlinNoise(IN.world_position_pass.x * 10.0, IN.world_position_pass.z * 10.0);

            if(resFromNoise < _ForestHeight){
                o.Albedo = float4(73.0 / 255.0, 179.0 / 255.0, 114.0 / 255.0,1.0);
            }else if(resFromNoise < _StoneHeight){
                o.Albedo = float4(105.0 / 255.0, 119.0 / 255.0, 125.0 / 255.0,1.0);
            }else{
                o.Albedo = float4(252.0 / 255.0, 252.0 / 255.0, 237.0 / 255.0,1.0);
            }

            o.Albedo += (res2FromNoise - 0.5) / 10.0;

            o.Normal = getNormal(IN.world_position_pass.xz);
            o.Smoothness = 0.0;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
