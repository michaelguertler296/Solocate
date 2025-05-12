import Foundation
import CoreLocation

class LocationEstimator {

    private var timeZoneOffset: Int = -7 // PST

    func estimateLocation(solarAz: Double, solarEl: Double, initialLat: Double, initialLon: Double) -> (Double, Double) {
        let coarseSearchRadiusKm = 1000.0
        let fineSearchRadiusKm = 50.0
        let coarseStepKm = 50.0
        let fineStepKm = 1.0
        let extrafineSearchRadiusKm = 1.0
        let extrafineStepKm = 0.1

        func searchAround(latCenter: Double, lonCenter: Double, radiusKm: Double, stepKm: Double) -> (Double, Double, Double) {
            let degreePerKmLat = 1.0 / 111.0
            let degreePerKmLon = 1.0 / (111.320 * cos(latCenter * .pi / 180))

            let latRadius = radiusKm * degreePerKmLat
            let lonRadius = radiusKm * degreePerKmLon

            var bestLat = latCenter
            var bestLon = lonCenter
            var minError = Double.greatestFiniteMagnitude

            for latOffset in stride(from: -latRadius, through: latRadius, by: stepKm * degreePerKmLat) {
                for lonOffset in stride(from: -lonRadius, through: lonRadius, by: stepKm * degreePerKmLon) {
                    let testLat = latCenter + latOffset
                    let testLon = lonCenter + lonOffset

                    guard testLat >= -90, testLat <= 90, testLon >= -180, testLon <= 180 else {
                        continue
                    }

                    let (testAz, testEl) = solarCalculation(lat: testLat, lon: testLon)
                    let azError = abs(testAz - solarAz)
                    let elError = abs(testEl - solarEl)
                    let totalError = azError + 10 * elError

                    if totalError < minError {
                        minError = totalError
                        bestLat = testLat
                        bestLon = testLon
                    }
                }
            }

            return (bestLat, bestLon, minError)
        }

        let (coarseLat, coarseLon, _) = searchAround(latCenter: initialLat, lonCenter: initialLon, radiusKm: coarseSearchRadiusKm, stepKm: coarseStepKm)
        let (fineLat, fineLon, _) = searchAround(latCenter: coarseLat, lonCenter: coarseLon, radiusKm: fineSearchRadiusKm, stepKm: fineStepKm)
        let (extrafineLat, extrafineLon, minError) = searchAround(latCenter: fineLat, lonCenter: fineLon, radiusKm: extrafineSearchRadiusKm, stepKm: extrafineStepKm)

        print("Estimated Location → Latitude: \(extrafineLat), Longitude: \(extrafineLon), Error: \(String(format: "%.4f", minError))")
        
        return (round(fineLat * 10000) / 10000, round(fineLon * 10000) / 10000)
    }

    // Solar Calculations

    private func calculateJulianDate(date: Date) -> Double {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: TimeZone(secondsFromGMT: 0)!, from: date)

        guard var year = components.year,
              var month = components.month,
              let day = components.day,
              let hour = components.hour,
              let minute = components.minute,
              let second = components.second else {
            return 0
        }

        if month <= 2 {
            year -= 1
            month += 12
        }

        let dayFraction = Double(day) + Double(hour)/24.0 + Double(minute)/1440.0 + Double(second)/86400.0
        let A = year / 100
        let B = 2 - A + (A / 4)

        let JD = Double(Int(365.25 * Double(year + 4716))) +
                 Double(Int(30.6001 * Double(month + 1))) +
                 dayFraction + Double(B) - 1524.5
        return JD
    }

    private func julianCenturies(julianDate: Double) -> Double {
        return (julianDate - 2451545.0) / 36525.0
    }

    private func solarCalculation(lat: Double, lon: Double) -> (Double, Double) {
        let now = Date()
        let jd = calculateJulianDate(date: now)
        let T = julianCenturies(julianDate: jd)
        let nowCalendar = Calendar(identifier: .gregorian)
        let secondsSinceMidnight = Double(nowCalendar.component(.hour, from: now) * 3600 +
                                          nowCalendar.component(.minute, from: now) * 60 +
                                          nowCalendar.component(.second, from: now))
        let fractionOfDay = secondsSinceMidnight / 86400.0
        let geomMeanLongSun = fmod(280.46646 + T * (36000.76983 + T * 0.0003032), 360)
        let geomMeanAnomSun = 357.52911 + T * (35999.05029 - 0.0001537 * T)
        let eccentEarthOrbit = 0.016708634 - T * (0.000042037 + 0.0000001267 * T)
        let sunEqOfCtr = sinDeg(geomMeanAnomSun) * (1.914602 - T * (0.004817 + 0.000014 * T)) +
                         sinDeg(2 * geomMeanAnomSun) * (0.019993 - 0.000101 * T) +
                         sinDeg(3 * geomMeanAnomSun) * 0.000289
        let sunTrueAnom = geomMeanLongSun + sunEqOfCtr
        let sunAppLong = sunTrueAnom - 0.00569 - 0.00478 * sinDeg(125.04 - 1934.136 * T)
        let meanObliqEcliptic = 23.0 + (26.0 + ((21.448 - T * (46.815 + T * (0.00059 - T * 0.001813)))) / 60.0) / 60.0
        let obliqCorr = meanObliqEcliptic + 0.00256 * cosDeg(125.04 - 1934.136 * T)
        let sunDeclin = asinDeg(sinDeg(obliqCorr) * sinDeg(sunAppLong))
        let varY = tanDeg(obliqCorr / 2.0)
        let y = varY * varY
        let eqOfTime = 4 * radToDeg(y * sinDeg(2 * geomMeanLongSun)
                          - 2 * eccentEarthOrbit * sinDeg(geomMeanAnomSun)
                          + 4 * eccentEarthOrbit * y * sinDeg(geomMeanAnomSun) * cosDeg(2 * geomMeanLongSun)
                          - 0.5 * y * y * sinDeg(4 * geomMeanLongSun)
                          - 1.25 * eccentEarthOrbit * eccentEarthOrbit * sinDeg(2 * geomMeanAnomSun))
        let trueSolarTime = calculateTimeValue(e: fractionOfDay, v: eqOfTime, longitude: lon, timeZone: -7)
        let hourAngle = hourAngle(solarTimeMinutes: trueSolarTime)
        let solarZenithAngle = solarZenithAngle(latitude: lat, declination: sunDeclin, hourAngle: hourAngle)
        let solarElevation = 90.0 - solarZenithAngle
        let solarAzimuth = solarAzimuthAngle(latitude: lat, declination: sunDeclin, zenithAngle: solarZenithAngle, hourAngle: hourAngle)

        return (solarAzimuth, solarElevation)
    }

    func solarZenithAngle(latitude: Double, declination: Double, hourAngle: Double) -> Double {
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180
        let haRad = hourAngle * .pi / 180

        let cosZenith = sin(latRad) * sin(decRad) + cos(latRad) * cos(decRad) * cos(haRad)
        let zenithRad = acos(cosZenith)

        return zenithRad * 180 / .pi
    }

    func hourAngle(solarTimeMinutes: Double) -> Double {
        let ha = solarTimeMinutes / 4
        return ha < 0 ? ha + 180 : ha - 180
    }

    func calculateTimeValue(e: Double, v: Double, longitude: Double, timeZone: Double) -> Double {
        let result = (e * 1440) + v + (4 * longitude) - (60 * timeZone)
        return result.truncatingRemainder(dividingBy: 1440)
    }

    func solarAzimuthAngle(latitude: Double, declination: Double, zenithAngle: Double, hourAngle: Double) -> Double {
        let latRad = latitude * .pi / 180
        let decRad = declination * .pi / 180
        let zenRad = zenithAngle * .pi / 180

        let numerator = sin(latRad) * cos(zenRad) - sin(decRad)
        let denominator = cos(latRad) * sin(zenRad)

        var azimuth = acos(numerator / denominator) * 180 / .pi

        if hourAngle > 0 {
            azimuth = fmod(azimuth + 180, 360)
        } else {
            azimuth = fmod(540 - azimuth, 360)
        }

        return azimuth
    }

    // Trig Helpers
    private func sinDeg(_ degrees: Double) -> Double {
        return sin(degrees * .pi / 180)
    }
    private func cosDeg(_ degrees: Double) -> Double {
        return cos(degrees * .pi / 180)
    }
    private func tanDeg(_ degrees: Double) -> Double {
        return tan(degrees * .pi / 180)
    }
    private func acosDeg(_ value: Double) -> Double {
        return acos(value) * 180 / .pi
    }
    private func asinDeg(_ value: Double) -> Double {
        return asin(value) * 180 / .pi
    }
    private func radToDeg(_ radians: Double) -> Double {
        return radians * 180 / .pi
    }
}
