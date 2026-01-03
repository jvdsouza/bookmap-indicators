# Docker Java Builder

A Docker-based build system for compiling Java projects into JAR files. Supports single files, multi-file projects, Maven, and Gradle.

## Prerequisites

- Docker installed and running
- Java source files or project directory

## Supported Project Types

1. **Single Java File** - A standalone .java file
2. **Multi-file Java Project** - Multiple .java files in a directory structure
3. **Maven Project** - Project with pom.xml
4. **Gradle Project** - Project with build.gradle or build.gradle.kts

## Usage

### Windows

```bash
build.bat <path-to-file-or-directory> [main-class-name]
```

### Linux/Mac

```bash
chmod +x build.sh
./build.sh <path-to-file-or-directory> [main-class-name]
```

## Examples

### Single Java File

```bash
# Windows
build.bat Example.java

# Linux/Mac
./build.sh Example.java
```

Output: `Example.jar`

### Single File with Explicit Main Class

```bash
# Windows
build.bat MyApp.java com.example.MyApp

# Linux/Mac
./build.sh MyApp.java com.example.MyApp
```

### Multi-file Java Project

For projects with multiple .java files organized in packages:

```bash
# Windows
build.bat examples/multifile-project com.example.Main

# Linux/Mac
./build.sh examples/multifile-project com.example.Main
```

Output: `multifile-project.jar`

**Note**: Main class name is required for multi-file projects.

### Maven Project

For projects with a `pom.xml` file:

```bash
# Windows
build.bat examples/maven-project

# Linux/Mac
./build.sh examples/maven-project
```

Output: `maven-project.jar`

The script automatically detects the Maven project and uses `mvn clean package`.

### Gradle Project

For projects with a `build.gradle` or `build.gradle.kts` file:

```bash
# Windows
build.bat examples/gradle-project

# Linux/Mac
./build.sh examples/gradle-project
```

Output: `gradle-project.jar`

The script automatically detects the Gradle project and uses `gradle clean build`.

## How It Works

1. Detects the project type (single file, multi-file, Maven, or Gradle)
2. Creates a Docker container with the appropriate build environment:
   - OpenJDK 17 for single/multi-file projects
   - Maven 3.9 with OpenJDK 17 for Maven projects
   - Gradle 8.5 with JDK 17 for Gradle projects
3. Compiles the project inside the container
4. Packages it into a JAR file
5. Copies the JAR to your current directory
6. Cleans up the container and temporary files

## Running the JAR

After building, run your JAR file with:

```bash
java -jar <output-file>.jar
```

## Example Projects

This repository includes example projects for testing:

- `Example.java` - Single file example
- `examples/multifile-project/` - Multi-file Java project
- `examples/maven-project/` - Maven project example
- `examples/gradle-project/` - Gradle project example

## Notes

- For single files, the main class is automatically determined from the filename
- For multi-file projects, you must specify the fully qualified main class name
- Maven and Gradle projects should have the main class configured in their build files
- The build process skips tests by default for faster builds
- All Docker containers and images are cleaned up after building
- JAR files are created in your current working directory

## Dockerfiles

The build system uses different Dockerfiles for each project type:

- `Dockerfile.maven` - Maven projects
- `Dockerfile.gradle` - Gradle projects
- `Dockerfile.multifile` - Multi-file Java projects
- Single files use a dynamically generated Dockerfile

## Troubleshooting

**Build fails for multi-file project**: Make sure to provide the fully qualified main class name (e.g., `com.example.Main`)

**Docker permission errors**: Ensure Docker is running and you have permission to run Docker commands

**JAR not found**: Check the build output for errors during compilation
