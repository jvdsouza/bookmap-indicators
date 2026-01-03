FROM openjdk:17-slim

WORKDIR /build

# Copy the Java file into the container
COPY ${JAVA_FILE} .

# Compile the Java file
RUN javac *.java

# Create a manifest file
RUN echo "Main-Class: ${MAIN_CLASS}" > manifest.txt

# Create the JAR file
RUN jar cfm output.jar manifest.txt *.class

# The JAR will be copied out by the build script
CMD ["echo", "Build complete"]
