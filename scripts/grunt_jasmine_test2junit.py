#!/opt/local/bin/python
import re, os, fileinput, sys

# script expects to be run from root of repo
output_path = "tests/reports/js"

scanning = False

#Transit invokeNative and queueNative queueNative : works fine with explicit calls of handleInvocationQueue...OK
#Transit invokeNative and queueNative queueNative : it respects invocationQueueMaxLen...ERROR
re_test = re.compile(r"^([^:]+) : (.*)...(.{2,8})$")

#118 assertions passed in 36 specs (47ms)
#2/118 assertions failed in 36 specs (45ms) Use --force to continue.
re_summary = re.compile(r".*\d+ assertions (passed|failed) in \d+ specs \((\d+)ms.*")

passed = 0
failed = 0
timeInSeconds = 0
out = ""

for line in fileinput.input():
    line = line.strip()
    print line
    if line == "Running specs for SpecRunner.html":
        scanning = True

    match = re_summary.match(line)
    if match:
        timeInSeconds = float(match.group(2)) / 1000
        break

    if scanning:
        match = re_test.match(line)
        if match:
            out += "  <testcase classname='%s' name='%s'>" % (match.group(1), match.group(2))
            if match.group(3) != "OK":
                failed += 1
                out += "<failure></failure>"
            else:
                passed += 1
            out += "</testcase>\n"

out = """<?xml version='1.0' encoding='UTF-8' ?>
<testsuite errors="0" failures="%d" package="Jasmine" name="JasmineTests" tests="%d" time="%.3f">
""" % (failed, failed+passed, timeInSeconds) + out + "</testsuite>"

if not os.path.exists(output_path):
    os.makedirs(output_path)
with open(output_path + "/TEST-Jasmine.xml", "w") as f:
    f.write(out)


