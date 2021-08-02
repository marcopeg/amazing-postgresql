# Run PostgreSQL queries on JMeter
Step by step tutorial and resource collection

---

## Prerequisites

- PostgreSQL running on your machine
- JVM 8+
- JMeter binaries

👉 Scroll down for the detailed instructions how to resolve the prerequisites.

## Setup

I followed this video to get my first examples running:
https://www.youtube.com/watch?v=m1dyGp6qVUo

I used `select now()` as first query, so you don't need any particular data structure ready.

## Resolving Prerequisites

### Install Java on MacOS

Here is a good step-by-step video:
https://www.youtube.com/watch?v=NSvtis2fGlA

Here is how to download Java SDK without Oracle login:
https://gist.github.com/wavezhang/ba8425f24a968ec9b2a8619d7c2d86a6#gistcomment-3019424

In the end, I had to manually setup the `JAVA_HOME` variable:

```bash
export JAVA_HOME=/Library/Java/JavaVirtualMachines/jdk-16.0.2.jdk/Contents/Home
```



### Install JMeter on MacOS

I tried to run `brew install jmeter` and the app works, but there are errors in opening popups as for saving the project or adding configuration (eg. add the *jdbc* drivers *jar* file)

I followed this video:
https://www.youtube.com/watch?v=tPKe6eYnlUk

Here you can download the official last version of JMeter:
https://jmeter.apache.org/download_jmeter.cgi

But here you can download the last working build of it following info from [this thread](https://stackoverflow.com/questions/67615212/why-am-i-not-able-to-click-on-open-icon-in-jmeter):
https://ci-builds.apache.org/job/JMeter/job/JMeter-trunk/lastSuccessfulBuild/artifact/src/dist/build/distributions/

In the end, to make the command globally available, I set up an alias in my `~/.zshrc` file:

```bash
alias jmeter=/Users/xxx/JMeter5/apache-jmeter-5.5-SNAPSHOT/bin/jmeter.sh
```



### Download JDBC Driver:

Here is the link to download the driver:
https://jdbc.postgresql.org/download.html

I then moved the .jar into `/Users/xxx/JMeter5/extras` and linked it directly into my test file.
