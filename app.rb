#require 'charlock_holmes'
require "csv"
require "pathname"


Pathname.glob(Pathname.getwd.join("**/*")) do |source_path|
  # ファイルじゃないとき（ディレクトリーのとき）はスキップ
  filename =  source_path.to_s.split("/")[source_path.to_s.split("/").length - 1]
  next if filename.split(".").pop != "csv"
  base_file_name = filename.split(".")
  next if base_file_name[0]=~/_converted/
  output_file = File.dirname(source_path.to_s) + "/#{base_file_name[0]}_converted.csv"

  encoding = "CP932"
  csv_datas = CSV.read(source_path.to_s, encoding: "#{encoding}:UTF-8")

  head_map = {}
  key_val_map = {}
  res = {}

  head = csv_datas.shift

  head.each_with_index do |title, idx|
    head_map[idx] = title
  end

  csv_datas.each do |row|
    unless res[row[1]].nil?
      row.each_with_index do |val, idx|
        if head_map[idx] == "Creative" ||
          head_map[idx] == "通貨" ||
          head_map[idx] == "Date" ||
          head_map[idx] == "Margin(Agency)" ||
          head_map[idx] == "原価" ||
          head_map[idx] == "CPA消化金額" ||
          head_map[idx] == "CTR" ||
          head_map[idx] == "eCPC"
          next
        end
        res[row[1]][head_map[idx]] = res[row[1]][head_map[idx]] + val.to_f
        key_val_map[head_map[idx]] = key_val_map[head_map[idx]] + val.to_f
      end
    else
      res[row[1]] = {}
      row.each_with_index do |val, idx|
        if head_map[idx] == "Creative" ||
          head_map[idx] == "通貨" ||
          head_map[idx] == "Date" ||
          head_map[idx] == "Margin(Agency)" ||
          head_map[idx] == "原価" ||
          head_map[idx] == "CPA消化金額" ||
          head_map[idx] == "CTR" ||
          head_map[idx] == "eCPC"
          next
        end
        res[row[1]][head_map[idx]] = val.to_f
        key_val_map[head_map[idx]] = val.to_f
      end
    end
  end
  remove_keys = []
  mcv_keys = []
  key_val_map.each do |key, val|
    if val.to_i == 0
      remove_keys.push(key)
    else
      if key =~ /mCV/
        mcv_keys.push key
      end
    end
  end
  #p mcv_keys
  head = ["Title","Imp","消化","Click","CPC", "CTR", "mCV", "mCPA"]
  CSV.open(output_file,'w') do |body|
    body << head
    res.each do |title, row|
      p row
      output_row = []
      output_row.push(title)
      output_row.push(row["Imp"])
      output_row.push(row["消化"])
      output_row.push(row["Click"])
      output_row.push(row["消化"]/row["Click"])
      output_row.push((row["Click"]/row["Imp"])*100)
      mcv_count = nil
      mcv_keys.each do |key|
        if key.include? "CV (Click)"
          mcv_count = row[key]
        end
      end
      unless mcv_count.nil?
        output_row.push(mcv_count)
      end
      output_row.push(row["消化"]/mcv_count)
      #p output_row
      body << output_row
    end
  end
end
