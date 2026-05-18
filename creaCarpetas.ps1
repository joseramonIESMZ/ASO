$dirs = @(
"docs/proyecto",
"docs/sprints/sprint-00",
"docs/sprints/sprint-01",
"docs/sprints/sprint-02",
"docs/sprints/sprint-03",
"docs/sprints/sprint-00-prima",
"docs/sprints/sprint-04",
"docs/sprints/sprint-05",
"docs/apuntes/windows-server",
"docs/apuntes/powershell",
"docs/apuntes/linux",
"docs/apuntes/samba",
"docs/apuntes/sql-server",
"docs/apuntes/proxmox",
"docs/scripts/powershell",
"docs/scripts/bash",
"docs/troubleshooting",
"docs/evaluacion",
"docs/assets/img",
"docs/assets/diagrams",
"docs/assets/css",
"docs/assets/downloads",
"overrides"
)

foreach ($dir in $dirs) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

$files = @(
"README.md",
"mkdocs.yml",
"requirements.txt",
"docs/index.md",
"docs/proyecto/descripcion-general.md",
"docs/proyecto/infraestructura.md",
"docs/proyecto/arquitectura-red.md",
"docs/proyecto/metodologia-scrum.md",
"docs/proyecto/evaluacion-ra-ce.md",
"docs/troubleshooting/index.md",
"docs/evaluacion/ra-ce.md",
"docs/evaluacion/instrumentos.md",
"docs/evaluacion/rubricas.md",
"docs/evaluacion/listas-cotejo.md",
"overrides/main.html"
)

foreach ($file in $files) {
    if (-not (Test-Path $file)) {
        New-Item -ItemType File -Path $file -Force | Out-Null
    }
}