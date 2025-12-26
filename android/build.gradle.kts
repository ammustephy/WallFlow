import com.android.build.gradle.BaseExtension
import org.jetbrains.kotlin.gradle.tasks.KotlinCompile

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

subprojects {
    val project = this
    
    // Fix missing namespace for plugins (AGP 8+ requirement)
    project.plugins.withId("com.android.library") {
        val android = project.extensions.getByName("android") as BaseExtension
        if (android.namespace == null) {
            android.namespace = "com.wallflow.${project.name.replace("-", ".").replace("_", ".")}"
        }
    }

    project.plugins.withId("com.android.application") {
        val android = project.extensions.getByName("android") as BaseExtension
        if (android.namespace == null) {
            android.namespace = "com.wallflow.${project.name.replace("-", ".").replace("_", ".")}"
        }
    }

    // Dynamic Configuration to bypass "already evaluated" and "finalized" issues
    fun configureJvmTarget() {
        // Force the tasks
        project.tasks.withType<JavaCompile> {
            sourceCompatibility = "11"
            targetCompatibility = "11"
        }
        project.tasks.withType<KotlinCompile> {
            kotlinOptions {
                jvmTarget = "11"
            }
        }
        
        // Force the extension if possible (Some AGP checks look here)
        if (project.extensions.findByName("android") != null) {
            val android = project.extensions.getByName("android") as BaseExtension
            try {
                android.compileOptions {
                    sourceCompatibility = JavaVersion.VERSION_11
                    targetCompatibility = JavaVersion.VERSION_11
                }
            } catch (e: Exception) {
                // Ignore if finalized
            }
        }
    }

    if (project.state.executed) {
        configureJvmTarget()
    } else {
        project.afterEvaluate {
            configureJvmTarget()
        }
    }

    // Global Manifest Fix: Strips 'package' attribute from source manifests
    project.tasks.configureEach {
        if (name.contains("process") && name.contains("Manifest")) {
            doFirst {
                val manifestFile = project.file("src/main/AndroidManifest.xml")
                if (manifestFile.exists()) {
                    try {
                        val content = manifestFile.readText()
                        if (content.contains("package=\"")) {
                            val newContent = content.replace(Regex("package=\"[^\"]*\""), "")
                            manifestFile.writeText(newContent)
                            logger.lifecycle("Successfully stripped package attribute from ${project.name} manifest")
                        }
                    } catch (e: Exception) {
                        // Silent fail
                    }
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
