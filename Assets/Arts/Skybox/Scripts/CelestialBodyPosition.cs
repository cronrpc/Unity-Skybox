using UnityEngine;

public class CelestialBodyPosition : MonoBehaviour
{
    [Tooltip("Current time (in days)")]
    public float d = 0f;
    public float dBias = 0f;

    [Tooltip("Days it takes to complete one orbit (e.g., 365 for Earth)")]
    public float yearDay = 365f;

    [Tooltip("Observer's latitude (°), positive for north, negative for south")]
    [Range(-90f, 90f)]
    public float latitude = 0f;

    [Tooltip("Observer's longitude (°), positive for east, negative for west")]
    [Range(-180f, 180f)]
    public float longitude = 0f;

    [Tooltip("Axial tilt (°), default is 23.5°")]
    [Range(0f, 90f)]
    public float tilt = 23.5f;

    [Tooltip("Transform representing the sunlight in the scene (e.g., a directional light)")]
    public Transform sun;

    void Update()
    {
        // —— 1. Angle Calculations —— //
        float selfAngle = ((d + dBias) % 1f) * 360f;              // Rotation angle (daily rotation)
        float orbitAngle = ((d + dBias) / yearDay) * 360f;        // Orbital angle (ecliptic longitude)

        // Convert to radians
        float phi = latitude * Mathf.Deg2Rad;               // Latitude
        float lambda = longitude * Mathf.Deg2Rad;              // Longitude
        float epsilon = tilt * Mathf.Deg2Rad;                   // Axial tilt
        float L = orbitAngle * Mathf.Deg2Rad;             // Ecliptic longitude
        float H = (lambda - selfAngle * Mathf.Deg2Rad);        // Hour angle (adjusted by longitude)

        // —— 2. Calculate Solar Declination sigma —— //
        float sigma = Mathf.Asin(Mathf.Sin(epsilon) * Mathf.Sin(L));

        // —— 3. Calculate Solar Altitude (alt) and Azimuth (az) —— //
        float sinAlt = Mathf.Sin(phi) * Mathf.Sin(sigma)
                     + Mathf.Cos(phi) * Mathf.Cos(sigma) * Mathf.Cos(H);
        float alt = Mathf.Asin(sinAlt);

        float cosAz = (Mathf.Sin(sigma) - Mathf.Sin(alt) * Mathf.Sin(phi))
                    / (Mathf.Cos(alt) * Mathf.Cos(phi));
        cosAz = Mathf.Clamp(cosAz, -1f, 1f);
        float az = Mathf.Acos(cosAz);

        if (Mathf.Sin(H) > 0f)
            az = 2f * Mathf.PI - az;

        // —— 4. Coordinate Conversion —— //
        float azEast = Mathf.PI / 2f - az;

        Vector3 dir;
        dir.x = -Mathf.Cos(alt) * Mathf.Cos(azEast); 
        dir.y = Mathf.Sin(alt);                      
        dir.z = Mathf.Cos(alt) * Mathf.Sin(azEast);  

        dir = -dir;

        if (sun != null)
            sun.rotation = Quaternion.LookRotation(dir, Camera.main.transform.up);
    }
}
