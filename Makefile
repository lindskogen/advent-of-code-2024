
build-all:
	find day* -name 'solution.zig' -exec zig build-exe {} \;

test-all:
	find day* -name 'solution.zig' -exec zig test {} \;

fmt:
	zig fmt day*/solution.zig

run-all:
	find day* -name 'solution.zig' -exec zig run {} \;

gen-%:
	mkdir day$*
	touch day$*/input
	cp template/solution.zig day$*/.
	sed -i.bak -e  "s_XX_$*_" day$*/solution.zig && rm day$*/solution.zig.bak
