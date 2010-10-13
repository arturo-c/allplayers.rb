# Hate, hate, hate

def apci_field_shoe_size(size_text)
  size_map = {
    "Adult - Male - 2"=>"86",
    "Toddler - 6.5"=>"11",
    "Youth - 11"=>"48",
    "Youth - 13.5"=>"53",
    "Toddler - 7"=>"12",
    "Adult - Male - 10"=>"102",
    "Adult - Male - 3"=>"88",
    "Youth - 12"=>"50",
    "Youth - 14.5"=>"55",
    "Toddler - 8"=>"14",
    "Toddler - 10.5"=>"19",
    "Adult - Female - 1.5"=>"57",
    "Toddler - 7.5"=>"13",
    "Adult - Male - 11"=>"104",
    "Adult - Male - 4"=>"90",
    "Adult - Female - 10.5"=>"75",
    "Toddler - 9"=>"16",
    "Toddler - 11.5"=>"21",
    "Adult - Female - 1"=>"56",
    "Adult - Female - 2.5"=>"59",
    "Toddler - 8.5"=>"15",
    "Youth - 13"=>"52",
    "Adult - Male - 12"=>"106",
    "Adult - Male - 5"=>"92",
    "Adult - Female - 11.5"=>"77",
    "Toddler - 12.5"=>"23",
    "Adult - Female - 2"=>"58",
    "Adult - Female - 3.5"=>"61",
    "Toddler - 9.5"=>"17",
    "Youth - 14"=>"54",
    "Adult - Male - 13"=>"108",
    "Adult - Male - 6"=>"94",
    "Adult - Female - 12.5"=>"79",
    "Toddler - 13.5"=>"25",
    "Youth - 1"=>"28",
    "Adult - Female - 3"=>"60",
    "Adult - Female - 4.5"=>"63",
    "Adult - Male - 14"=>"110",
    "Adult - Male - 7"=>"96",
    "Adult - Male - 1.5"=>"85",
    "Adult - Female - 13.5"=>"81",
    "Youth - 2"=>"30",
    "Adult - Female - 4"=>"62",
    "Adult - Female - 5.5"=>"65",
    "Toddler - 14.5"=>"27",
    "Adult - Male - 8"=>"98",
    "Adult - Male - 2.5"=>"87",
    "Adult - Female - 14.5"=>"83",
    "Adult - Female - 6.5"=>"67",
    "Youth - 3"=>"32",
    "Adult - Female - 5"=>"64",
    "Youth - 1.5"=>"29",
    "Toddler - 10"=>"18",
    "Adult - Male - 9"=>"100",
    "Adult - Male - 3.5"=>"89",
    "Adult - Female - 7.5"=>"69",
    "Adult - Female - 6"=>"66",
    "Youth - 2.5"=>"31",
    "Toddler - 11"=>"20",
    "Youth - 4"=>"34",
    "Adult - Male - 4.5"=>"91",
    "Adult - Female - 8.5"=>"71",
    "Adult - Female - 7"=>"68",
    "Youth - 3.5"=>"33",
    "Toddler - 12"=>"22",
    "Youth - 5"=>"36",
    "Adult - Male - 5.5"=>"93",
    "Adult - Female - 9.5"=>"73",
    "Adult - Female - 8"=>"70",
    "Youth - 4.5"=>"35",
    "Toddler - 13"=>"24",
    "Youth - 6"=>"38",
    "Adult - Male - 6.5"=>"95",
    "Adult - Female - 9"=>"72",
    "Youth - 5.5"=>"37",
    "Toddler - 14"=>"26",
    "Youth - 7"=>"40",
    "Adult - Male - 7.5"=>"97",
    "Youth - 6.5"=>"39",
    "Youth - 8"=>"42",
    "Adult - Male - 8.5"=>"99",
    "Toddler - 1"=>"0",
    "Youth - 7.5"=>"41",
    "Youth - 9"=>"44",
    "Adult - Male - 9.5"=>"101",
    "Toddler - 2"=>"2",
    "Youth - 8.5"=>"43",
    "Adult - Male - 10.5"=>"103",
    "Adult - Female - 10"=>"74",
    "Toddler - 1.5"=>"1",
    "Toddler - 3"=>"4",
    "Adult - Male - 11.5"=>"105",
    "Adult - Female - 11"=>"76",
    "Toddler - 2.5"=>"3",
    "Toddler - 4"=>"6",
    "Youth - 9.5"=>"45",
    "Adult - Male - 12.5"=>"107",
    "Adult - Female - 12"=>"78",
    "Toddler - 3.5"=>"5",
    "Youth - 10.5"=>"47",
    "Adult - Male - 13.5"=>"109",
    "Adult - Female - 13"=>"80",
    "Toddler - 4.5"=>"7",
    "Youth - 10"=>"46",
    "Youth - 11.5"=>"49",
    "Toddler - 5"=>"8",
    "Adult - Male - 14.5"=>"111",
    "Adult - Male - 1"=>"84",
    "Adult - Female - 14"=>"82",
    "Toddler - 5.5"=>"9",
    "Youth - 12.5"=>"51",
    "Toddler - 6"=>"10",
  }
  if size_map.has_key?(size_text)
    return size_map[size_text]
  else
    raise 'Invalid shoe size.'
  end
end

def apci_field_shirt_size(size_text)
  size_map = {
    "XXL"=>"0",
    "XL"=>"1",
    "L"=>"2",
    "M"=>"3",
    "S"=>"4",
    "YL"=>"5",
    "YM"=>"6",
    "YS"=>"7",
  }
  if size_map.has_key?(size_text)
    return size_map[size_text]
  else
    raise 'Invalid shirt size.'
  end
end

def apci_field_height(height_text)
  arr = height_text.split("'")
  return height_text unless arr.length > 1
  feet = arr[0].strip.to_i
  inches = arr[1].split('"').first.strip.to_i
  height = feet + ((inches / 12.0) * 1000).round/1000.0
  return height.to_s
end