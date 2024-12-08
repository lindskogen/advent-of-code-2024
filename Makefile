
build-all:
	find day* -name 'solution.zig' -exec zig build-exe {} \;

test-all:
	find day* -name 'solution.zig' -exec zig test {} \;

fmt:
	zig fmt day*/solution.zig
