Rails app generated with [lewagon/rails-templates](https://github.com/lewagon/rails-templates), created by the [Le Wagon coding bootcamp](https://www.lewagon.com) team.

## Asistente médico con RubyLLM

El proyecto integra [RubyLLM](https://rubyllm.com) para ofrecer un asistente contextual que opera según el rol del usuario:

- **Pacientes**: chat para dudas médicas, subida de exámenes (para interpretación o para guardarlos en el historial).
- **Doctores**: copiloto clínico que contesta preguntas sobre diagnósticos y métricas de agenda diaria/semanal.
- **Administradores**: asistente operativo para conteos de citas, pacientes, doctores e institutos.

### Variables de entorno

Configura una clave válida del proveedor que prefieras (OpenAI, OpenRouter, etc.). Ejemplo para OpenAI:

```bash
export OPENAI_API_KEY=sk-...
# Opcional
export RUBYLLM_MODEL=gpt-4.1-mini
export RUBYLLM_TIMEOUT=180
```

También puedes definir `OPENROUTER_API_KEY`, `GEMINI_API_KEY` o `ANTHROPIC_API_KEY` si usas otros proveedores.

### Migraciones necesarias

Ejecuta las migraciones para activar Active Storage y las nuevas tablas de conversación/archivos:

```bash
bin/rails db:migrate
```

Luego asigna permisos de escritura en `storage/` si usas servicio local.
