allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Keep all build artifacts in the Flutter root build/ directory
subprojects {
    val newBuildDir = rootProject.projectDir.parentFile.resolve("build").resolve(project.name)
    project.layout.buildDirectory.value(rootProject.layout.projectDirectory.dir(newBuildDir.absolutePath))
}

subprojects {
    project.evaluationDependsOn(":app")

    // Workaround for Windows cross-drive builds:
    // Disable problematic unit test config tasks for plugins (stored on C:),
    // which fail when the build directory is on a different drive (F:).
    val tasksToDisable = listOf(
        "generateDebugUnitTestConfig",
        "generateReleaseUnitTestConfig"
    )
    tasksToDisable.forEach { taskName ->
        tasks.matching { it.name == taskName }.configureEach {
            enabled = false
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
