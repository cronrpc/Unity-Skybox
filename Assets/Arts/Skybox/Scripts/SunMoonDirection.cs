using UnityEngine;

/// <summary>
/// Computes the direction vectors from the local horizontal plane toward the Sun and Moon,
/// given day-of-year, hour of day, latitude, longitude and timezone.
/// X+ is East, Z+ is North, Y+ is Up.
/// </summary>
public class SunMoonDirection : MonoBehaviour
{
    [Header("Date/Time Inputs")]
    [Tooltip("Day of year (1-365)")]
    public int day = 1;

    [Tooltip("Hour of day (0-24)")]
    public float hour = 12f;

    [Header("Location Inputs")]
    [Tooltip("Latitude in degrees (North+)")]
    public float latitude = 0f;

    [Tooltip("Longitude in degrees (East+)")]
    public float longitude = 0f;

    [Tooltip("Timezone offset from UTC in hours, e.g. +8 for UTC+8")]
    public float timezone = 0f;

    [Header("Outputs")]
    public Vector3 sunDirection;
    public Vector3 moonDirection;
    
    [Header("Sun and Moon")]
    [SerializeField] Transform _Sun = default;
    [SerializeField] Transform _Moon = default;

    [Header("Auto Progress")]
    [SerializeField] bool _autoProgress = true;
    [SerializeField] float HoursPerSeconds = 24;
    [SerializeField] int DayPer24Hours = 8;
    
    void Update()
    {
        if (_autoProgress)
        {
            hour += HoursPerSeconds * Time.deltaTime;
            if (hour > 24)
            {
                hour = Mathf.Clamp(hour - 24, 0, 24);
                day = day>=365 ? 1 : day + DayPer24Hours;
            }
        }
        
        sunDirection  = CalculateSunDirection(day, hour, latitude, longitude, timezone);
        moonDirection = CalculateMoonDirection(day, hour, latitude, longitude, timezone);
        _Sun.transform.rotation = Quaternion.LookRotation(-sunDirection);
        _Moon.transform.rotation = Quaternion.LookRotation(-moonDirection);
    }

    Vector3 CalculateSunDirection(int N, float t, float latDeg, float lonDeg, float tz)
    {
        float latRad = latDeg * Mathf.Deg2Rad;

        float gamma = 2f * Mathf.PI / 365f * (N - 1 + (t - 12f) / 24f);

        float delta = 0.006918f
                      - 0.399912f * Mathf.Cos(gamma)
                      + 0.070257f * Mathf.Sin(gamma)
                      - 0.006758f * Mathf.Cos(2f * gamma)
                      + 0.000907f * Mathf.Sin(2f * gamma)
                      - 0.002697f * Mathf.Cos(3f * gamma)
                      + 0.00148f  * Mathf.Sin(3f * gamma);

        float Eq = 229.18f * (
            0.000075f
            + 0.001868f * Mathf.Cos(gamma)
            - 0.032077f * Mathf.Sin(gamma)
            - 0.014615f * Mathf.Cos(2f * gamma)
            - 0.040849f * Mathf.Sin(2f * gamma)
        );

        float timeOffset = Eq + 4f * lonDeg - 60f * tz;
        float TST = t * 60f + timeOffset;

        float Hdeg = (TST / 4f) - 180f;
        float H = Hdeg * Mathf.Deg2Rad;

        float sinElev = Mathf.Sin(latRad) * Mathf.Sin(delta)
                        + Mathf.Cos(latRad) * Mathf.Cos(delta) * Mathf.Cos(H);
        float elev = Mathf.Asin(sinElev); // radians

        float y = -Mathf.Sin(H);
        float x = Mathf.Tan(delta) * Mathf.Cos(latRad) - Mathf.Sin(latRad) * Mathf.Cos(H);
        float az = Mathf.Atan2(y, x); // radians

        float xOut = Mathf.Cos(elev) * Mathf.Sin(az);
        float yOut = Mathf.Sin(elev);
        float zOut = Mathf.Cos(elev) * Mathf.Cos(az);

        return new Vector3(xOut, yOut, zOut).normalized;
    }

    Vector3 CalculateMoonDirection(int day, float hour, float latDeg, float lonDeg, float tz)
    {
        float moonOrbitDays = 27.0f;
        float totalHours = (day % (int)moonOrbitDays) * 24f + hour;
        float orbitProgress = totalHours / (moonOrbitDays * 24f); // [0,1]
        float angle = orbitProgress * 360f;

        float inclination = 5f * Mathf.Deg2Rad;

        float x = Mathf.Cos(angle * Mathf.Deg2Rad);
        float y = Mathf.Sin(angle * Mathf.Deg2Rad) * Mathf.Cos(inclination);
        float z = Mathf.Sin(angle * Mathf.Deg2Rad) * Mathf.Sin(inclination);

        return new Vector3(x, y, z).normalized;
    }

}
