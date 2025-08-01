using System.Collections.Generic;
using UnityEngine;

public class DayIncreaseTool : MonoBehaviour
{
    public float DayPerSecond = 0.25f;
    public bool isEnable;
    public List<CelestialBodyPosition> celestialBodies = new List<CelestialBodyPosition>();
    
    void Update()
    {
        if (isEnable)
        {
            foreach (var t in celestialBodies)
            {
                t.d += DayPerSecond * Time.deltaTime;
            }
        }
    }
}
