class_name GameFormatting


static func stamina_cost_detail(value: float) -> String:
	return "%.2f" % maxf(0.0, value)


static func info_chip_number(value: float) -> String:
	var absolute := absf(value)
	if absolute > 0.000001 and absolute < 1.0:
		return trim_trailing_decimal_zeroes("%.2f" % value)
	return significant_digits(value, 3)


static func significant_digits(value: float, digits := 3) -> String:
	var safe_digits := maxi(1, digits)
	var absolute := absf(value)
	if absolute < 0.000001:
		return "0"
	var places := safe_digits - 1 - int(floor(log(absolute) / log(10.0)))
	if places < 0:
		var factor := pow(10.0, float(-places))
		return "%.0f" % (round(value / factor) * factor)
	places = mini(places, 6)
	var format := "%." + str(places) + "f"
	return trim_trailing_decimal_zeroes(format % value)


static func compact_number(value: float, digits := 3) -> String:
	var absolute := absf(value)
	if absolute < 1000.0:
		return trim_trailing_decimal_zeroes(significant_digits(value, digits))
	var suffixes := ["K", "M", "B", "T", "Qa", "Qi"]
	var scaled := value
	var suffix_index := -1
	while absf(scaled) >= 1000.0 and suffix_index < suffixes.size() - 1:
		scaled /= 1000.0
		suffix_index += 1
	var text := trim_trailing_decimal_zeroes(significant_digits(scaled, digits))
	if (text == "1000" or text == "-1000") and suffix_index < suffixes.size() - 1:
		scaled /= 1000.0
		suffix_index += 1
		text = trim_trailing_decimal_zeroes(significant_digits(scaled, digits))
	return "%s%s" % [text, suffixes[suffix_index]]


static func percent_points(value: float, digits := 3) -> String:
	return trim_trailing_decimal_zeroes(significant_digits(value, digits))


static func trim_trailing_decimal_zeroes(text: String) -> String:
	if text.find(".") == -1:
		return text
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return "0" if text == "-0" else text


static func duration(seconds: float) -> String:
	var total_seconds := maxi(0, int(ceil(seconds)))
	var hours := int(floor(float(total_seconds) / 3600.0))
	var minutes := int(floor(float(total_seconds % 3600) / 60.0))
	if hours > 0:
		return "%sh %sm" % [hours, minutes]
	return "%sm" % maxi(1, minutes)


static func countdown(seconds: int) -> String:
	var total := maxi(0, seconds)
	var hours := int(floor(float(total) / 3600.0))
	var minutes := int(floor(float(total % 3600) / 60.0))
	var secs := total % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, secs]
	return "%d:%02d" % [minutes, secs]
