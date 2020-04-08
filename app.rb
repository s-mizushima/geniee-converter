require "csv"
require "pathname"

mcpa_limit = 700

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
  res = []

  head = csv_datas.shift

  head.each_with_index do |title, idx|
    head_map[title] = idx
  end

  p head_map


  csv_datas.each.with_index(1) do |row, idx|

    if row[head_map["cv click"]].to_i > 0
      # mCVRが発生している場合
      # mcpa_limit/mCPA x CPCをbidpriceにする
      p "=== mCVR > 0 ==="
      p "cpc is #{row[head_map["cpc"]]}"
      p "bidprice is #{row[head_map["bidprice"]]}"
      p "mCPA is #{row[head_map["cpa/cpi"]]}"
      row[head_map["bidprice"]] = (row[head_map["bidprice"]].to_f * (mcpa_limit/(row[head_map["cpa/cpi"]].to_f)) ).round
      row[head_map["lowest bid price"]] =  row[head_map["bidprice"]] - 1
      if mcpa_limit > row[head_map["cpa/cpi"]].to_i
        #上限mCPAより安く収まっているもの -> 増額
        p "bidprice increased to #{row[head_map["bidprice"]]}"
      else
        # 上限mCPAを超えているもの -> 減額
        p "bidprice reduced to #{row[head_map["bidprice"]]}"
      end
    else
      # mCVRがまだ発生していないもの
      if row[head_map["total cost"]].to_i > mcpa_limit
        # cpa上限より消化が多いもの
        p "=== total cost > mcpa_limit ==="
        p "cpc is #{row[head_map["cpc"]]}"
        p "bidprice is #{row[head_map["bidprice"]]}"
        p "total cost is #{row[head_map["total cost"]]}"
        row[head_map["bidprice"]] = ( row[head_map["bidprice"]].to_f * (mcpa_limit/(row[head_map["total cost"]].to_f)) ).round
        row[head_map["lowest bid price"]] =  row[head_map["bidprice"]] - 1
        p "bidprice reduced to #{row[head_map["bidprice"]]}"
      elsif row[head_map["total cost"]].to_i == 0
        #消化がまだないもの
        p "=== cost 0 ==="
        p "cpc is #{row[head_map["cpc"]]}"
        p "bidprice is #{row[head_map["bidprice"]]}"
        p "total cost is #{row[head_map["total cost"]]}"
        row[head_map["bidprice"]] = row[head_map["bidprice"]].to_i + 1
        row[head_map["lowest bid price"]] =  row[head_map["bidprice"]] - 1
        p "bidprice increased to #{row[head_map["bidprice"]]}"
      else
        #上記いずれも当てはまらないもの
        #cpcより1円低い金額に設定
        p "=== few cost ==="
        p "cpc is #{row[head_map["cpc"]]}"
        p "bidprice is #{row[head_map["bidprice"]]}"
        p "total cost is #{row[head_map["total cost"]]}"
        row[head_map["bidprice"]] = row[head_map["cpc"]].to_i - 1
        row[head_map["lowest bid price"]] = row[head_map["bidprice"]] - 1
        p "bidprice reduced to #{row[head_map["bidprice"]]}"
      end
    end

    res.push(row)
  end
  #p mcv_keys
  head = head_map.keys
  CSV.open(output_file,'w') do |body|
    body << head
    res.each do |row|
      if row[head_map["bidprice"]] < 0
        row[head_map["bidprice"]] = 1
      end
      if row[head_map["lowest bid price"]] < 0
        row[head_map["lowest bid price"]] = 1
      end
      body << row
    end
  end
end
