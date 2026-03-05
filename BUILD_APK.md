# Cómo generar el APK de Stocky

## Requisitos previos
- Flutter SDK instalado (`flutter --version`)
- Android SDK en `C:\Android\Sdk` (ya configurado)
- Licencias aceptadas (`flutter doctor --android-licenses`)

## Comando

```bash
cd stocky
flutter build apk --release
```

El APK queda en:

```
build/app/outputs/flutter-apk/app-release.apk
```

## Variantes útiles

| Comando | Resultado |
|---|---|
| `flutter build apk --release` | APK universal (todos los CPU) |
| `flutter build apk --split-per-abi` | 3 APKs más pequeños por arquitectura |
| `flutter build apk --debug` | APK de debug (sin ofuscar) |

## Instalar directamente en dispositivo USB

```bash
flutter install
```

> Asegúrate de tener **Depuración USB** activada en el teléfono.
