using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Component_HeightFetchingTest : MonoBehaviour
{
    public float _Seed = 7383.0f;
    public float _Height = 2.0f;
    public float _Scale = 3.0f;

    float frac2(float n1){
        float n = Mathf.Abs(n1);
        return n - Mathf.Floor(n);
    }

    float rand(Vector2 myVector)  {
        return frac2(Mathf.Sin( Vector2.Dot(myVector, new Vector2(12.9898f,78.233f) )) * _Seed*1000.0f+364.0f);
    }

    Vector2 randVecAt(float x, float y){
        float choice = rand(new Vector2(x, y));
        if(choice < 0.25f){
            return new Vector2(-1.0f, -1.0f);
        }else if(choice < 0.5f){
            return new Vector2(1.0f, -1.0f);
        }else if(choice < 0.75f){
            return new Vector2(1.0f, 1.0f);
        }else{
            return new Vector2(-1.0f, 1.0f);
        }
    }

    float cosInterp(float n){
        return (Mathf.Cos(n*3.141592653589793238462f)+1.0f)/2.0f;
    }

    Vector2 Distance(Vector2 v1, Vector2 v2){
        return v2 - v1;
    }

    float PerlinNoise(float x, float y){
                                                                // X, Y
        Vector2 vec_random_0 = randVecAt(Mathf.Floor(x), Mathf.Floor(y)); // 0, 0
        Vector2 vec_random_1 = randVecAt(Mathf.Ceil(x), Mathf.Floor(y));  // 1, 0
        Vector2 vec_random_2 = randVecAt(Mathf.Ceil(x), Mathf.Ceil(y));   // 1, 1
        Vector2 vec_random_3 = randVecAt(Mathf.Floor(x), Mathf.Ceil(y));  // 0, 1
        
                                                                                    // X, Y
        Vector2 vec_dist_0 = Distance(new Vector2(Mathf.Floor(x), Mathf.Floor(y)), new Vector2(x, y));  // 0, 0
        Vector2 vec_dist_1 = Distance(new Vector2(Mathf.Ceil(x), Mathf.Floor(y)), new Vector2(x, y));   // 1, 0
        Vector2 vec_dist_2 = Distance(new Vector2(Mathf.Ceil(x), Mathf.Ceil(y)), new Vector2(x, y));    // 1, 1
        Vector2 vec_dist_3 = Distance(new Vector2(Mathf.Floor(x), Mathf.Ceil(y)), new Vector2(x, y));   // 0, 1
        
        float vec_dot_0 = Vector2.Dot(vec_random_0, vec_dist_0);
        float vec_dot_1 = Vector2.Dot(vec_random_1, vec_dist_1);
        float vec_dot_2 = Vector2.Dot(vec_random_2, vec_dist_2);
        float vec_dot_3 = Vector2.Dot(vec_random_3, vec_dist_3);
        
        float x10 = x - Mathf.Floor(x); // x10 is between 0 and 1
        float y10 = y - Mathf.Floor(y); // y10 is between 0 and 1
        
        // topleft && topright
        float upInterpolate = (vec_dot_0*cosInterp(x10))+(vec_dot_1*(1.0f-cosInterp(x10)));
        
        // bottomleft && bottomright
        float downInterpolate = (vec_dot_3*cosInterp(x10))+(vec_dot_2*(1.0f-cosInterp(x10)));

        float final = (upInterpolate*cosInterp(y10))+(downInterpolate*(1.0f-cosInterp(y10)));
        return final;
    }

    float HeightFunc(float posX, float posY){
        float posX2 = -posX-3.0f;
        float posY2 = posY-3.0f;
        return PerlinNoise(posX2, posY2) + ((posX2+posY2) / 5.0f);
    }

    float getHeightValue(Vector2 pos){
        Vector2 newPos = new Vector2((pos.x + 10.0f) / 20.0f, (pos.y + 10.0f) / 20.0f);
        return HeightFunc(newPos.x*_Scale, newPos.y*_Scale)*_Height;
    }

    void Update()
    {
        Vector3 worldVec = transform.position;
        worldVec = new Vector3(Mathf.Floor(worldVec.x), worldVec.y, Mathf.Floor(worldVec.z));
        
        Vector3 v0 = worldVec;
        v0 = new Vector3(v0.x, getHeightValue(new Vector2(v0.x, v0.z)), v0.z);

        transform.position = new Vector3(transform.position.x, Mathf.Floor(v0.y), transform.position.z);
    }
}
