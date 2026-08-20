.pragma library

function normalizeZones(value) {
  if (!Array.isArray(value)) return []
  var out = []
  for (var i = 0; i < value.length; i++) {
    var zone = String(value[i] === undefined || value[i] === null ? "" : value[i]).trim()
    if (!zone || out.indexOf(zone) !== -1 || zone === "__local__") continue
    out.push(zone)
  }
  return out.slice(0, 12)
}

function friendlyName(zone) {
  var parts = String(zone || "").split("/")
  var city = parts[parts.length - 1] || zone
  return city.replace(/_/g, " ")
}

function parseLine(line) {
  var parts = String(line || "").split("|")
  if (parts.length < 8) return null
  return {
    id: parts[0],
    time24: parts[1],
    time12: parts[2],
    ampm: parts[3],
    date: parts[4],
    weekday: parts[5],
    utcOffset: parts[6],
    abbr: parts[7]
  }
}

function parseTimesOutput(text) {
  var out = {}
  var lines = String(text || "").split("\n")
  for (var i = 0; i < lines.length; i++) {
    var line = lines[i].trim()
    if (!line) continue
    var parsed = parseLine(line)
    if (parsed) out[parsed.id] = parsed
  }
  return out
}

function dayBadge(zoneDate, localDate) {
  if (!zoneDate || !localDate || zoneDate === localDate) return ""
  var zoneParts = String(zoneDate).split("-")
  var localParts = String(localDate).split("-")
  if (zoneParts.length < 3 || localParts.length < 3) return ""
  var diff = Math.round((Date.UTC(Number(zoneParts[0]), Number(zoneParts[1]) - 1, Number(zoneParts[2]))
    - Date.UTC(Number(localParts[0]), Number(localParts[1]) - 1, Number(localParts[2]))) / 86400000)
  if (diff === 1) return "+1"
  if (diff === -1) return "−1"
  return ""
}
