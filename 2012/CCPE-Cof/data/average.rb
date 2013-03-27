#!/usr/bin/ruby

# get the file name
filename = ARGV[0]
startN = ARGV[1].to_i
endN = ARGV[2].to_i
if filename==nil or startN==nil or endN==nil
	puts "file name missing"
	puts "usage: average.rb [file name] [start size] [end size]"
	exit
else
	filename = filename.gsub(/\.\//, "");
	puts "input file: #{filename}"
	contents = File.open(filename, "r"){ |file| file.read }
end

outname = filename+".avg"
outfile = File.open(outname, "w")
outfile.puts "N\t\tTime(ft)\t\tTime(slp)\t\tOverhead(%)"

for n in (startN..endN).step(5000)

	t = contents.scan(/^#{n}\s+\d+\s+\d+\s+[\.\d]+\s+[\.\d]+\s+/);

	sum_ft=0;
	sum_nft=0;
	t.each do |i|
		nt=i.to_s.split(" ");
		sum_ft += nt[3].to_f;
		sum_nft += nt[4].to_f;
	end
	sum_ft /= t.length
	sum_nft /= t.length

	sum_ft = ((sum_ft*1000000.0).round)/1000000.0
	sum_nft = ((sum_nft*1000000.0).round)/1000000.0

	outfile.puts n.to_s+"\t\t"+sum_ft.to_s+"\t\t"+sum_nft.to_s+"\t\t"+(((((sum_ft-sum_nft)/sum_ft*100)*1000.0).round)/1000.0).to_s
end

outfile.close

puts "averaged result was written in #{outname}, done!"
