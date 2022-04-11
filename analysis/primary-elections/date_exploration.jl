# date exploration

using DataFrames, DataFramesMeta, Dates
import TSCSMethods.mean

trtd = @subset(dat, :primary .== 1);

trtdates = unique(trtd.date);

freq = @chain dat begin
    @subset(:date .∈ Ref(trtdates))
    groupby(:date)
    @combine(
        :cdr = mean(cols(vn.cdr)),
        :ccr = mean(cols(vn.ccr)),
        :cd = sum(:deathscum),
        :cc = sum(:casescum)
    )
    sort(:date)
end

freqtrt = @chain trtd begin
    groupby(:date)
    @combine(
        :primaries = sum(:primary),
        :cdr = mean(cols(vn.cdr)),
        :ccr = mean(cols(vn.ccr)),
        :cd = sum(:deathscum),
        :cc = sum(:casescum)
    )
    sort(:date)
end

#=
date groups

realistically, the number of primaries within a range is a necessary
grouping feature

1.
03-03, 03-10, 03-17
These are date ranges without completely defined matching periods.
There are a ton of primaries in this period.

2.
04-07,05-12,06-02,06-09

3.
06-23, 07-07, 07-11, 08-11

=#
