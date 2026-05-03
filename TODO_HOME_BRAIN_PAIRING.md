# TODO: Echo Desktop + Home Brain Pairing

Goal: a user can run Echo on their Windows computer, expose their local Echo brain through a tunnel, and connect from mobile while away from home.

## Current State

- `flutter run -d windows` can launch the Flutter Windows shell because the repo has a Windows runner.
- Mobile pairing screen exists at `lib/page/echo_tabs/pair_computer_screen.dart`.
- Pairing accepts a QR code, pasted URL, or JSON code containing `baseUrl`, `url`, `tunnelUrl`, or `echoUrl`.
- Pairing validates the desktop by calling `GET {url}/health`.
- If validation succeeds, the URL is saved in `EchoHostService` and used by `AuthService` / `EchoApiClient`.
- Backend Echo sidecar exists separately in `C:\Users\ASUS\Desktop\echo` and runs on port `8002`.
- vLLM startup scripts exist separately in `C:\Users\ASUS\Desktop\echo`, including `start_all.ps1`, `start_vllm.sh`, and `start_gemma4_e2b_vllm.sh`.

## Launch Blockers

1. Route all core chat traffic through `EchoHostService`
   - `lib/echo/echo_client.dart` still hardcodes `localhost:8002` / `10.0.2.2:8002`.
   - `ChatPage` uses `EchoClient().baseUrl + '/v1'` for local Echo fallback, so chat can ignore the paired tunnel.
   - `lib/voice/voice_service.dart` also hardcodes the local Echo base.
   - Fix: make `EchoClient` and `VoiceService` use `EchoHostService().resolvedUrl`.

2. Add a real desktop pairing screen
   - Windows app must show "Home Brain" or "Pair Mobile" status.
   - It must show:
     - Echo sidecar status: `GET http://localhost:8002/health`
     - authenticated system status: `/v1/system/health` after login
     - current tunnel URL
     - QR code for the mobile app to scan
   - Use existing `qr_flutter` dependency.

3. Generate the QR payload on desktop
   - Recommended payload:
     ```json
     {"type":"echo_home_brain","baseUrl":"https://example.trycloudflare.com","version":1}
     ```
   - Mobile already accepts `baseUrl`, so this works with the current scanner.
   - Add stricter validation later so random URLs are not silently accepted as Echo.

4. Make tunnel creation user-facing
   - Current manual path says to run:
     `cloudflared tunnel --url http://localhost:8002`
   - This is not launchable for normal users.
   - Desktop should either:
     - start bundled `cloudflared` itself, or
     - detect installed `cloudflared` and offer a guided one-click start.
   - Store the resulting tunnel URL in desktop state and show it as QR.

5. Define Echo Desktop download/install path
   - There is no product path for "download Echo Desktop" yet.
   - For first launch, ship a Windows build artifact from:
     `flutter build windows`
   - Later, package an installer with the backend, cloudflared, and setup scripts.

6. Make local brain startup explicit
   - Pairing does not start Echo sidecar or vLLM.
   - Desktop must clearly show:
     - Echo API running or not running
     - vLLM running or not running
     - Gemma lane running or not running
     - adapter loaded or not loaded
   - Add buttons:
     - Start Echo API
     - Start vLLM
     - Start Gemma vLLM lane
     - Restart tunnel
   - These can call local scripts first; later replace with a managed desktop service.

## Minimum Launch User Journey

1. User installs Echo Desktop on Windows.
2. User opens Echo Desktop.
3. Desktop checks local services.
4. If Echo sidecar is not running, user clicks `Start Home Brain`.
5. If vLLM is not running, user clicks `Start Local Model`.
6. User clicks `Start Secure Tunnel`.
7. Desktop shows a QR code containing the tunnel URL.
8. User opens Echo mobile.
9. User taps `My Computer`.
10. User scans the desktop QR code with the mobile camera.
11. Mobile tests `{tunnelUrl}/health`.
12. Mobile saves the tunnel URL.
13. All Echo API, chat context, save, feedback, model fallback, and voice calls use the tunnel.
14. Lab shows `Home Brain connected` and system health.

## Implementation Tasks

### Flutter App

- [ ] Replace `EchoClient._baseUrl` hardcoding with `EchoHostService().resolvedUrl`.
- [ ] Replace `VoiceService._echoBase` hardcoding with `EchoHostService().resolvedUrl`.
- [ ] Update default Echo provider endpoint after pairing, or ensure local Echo fallback ignores stale `settings_provider.dart` defaults.
- [ ] Add `HomeBrainScreen` for Windows/web desktop.
- [ ] Add a desktop `Pair Mobile` QR panel using `QrImageView`.
- [ ] Add mobile scanner success screen showing the connected host URL and health status.
- [ ] Add a disconnect/reset action for mobile and desktop.
- [ ] Hide or rewrite the old network sync QR copy so users do not confuse sync QR with home-brain QR.
- [ ] In onboarding, explain "My Computer" as "use your Windows Echo Desktop as the brain".

### Desktop Service Management

- [ ] Decide first launch approach: script-driven or bundled managed service.
- [ ] Add Windows buttons that run or guide:
  - `python main.py` for Echo API
  - `wsl -d Ubuntu-24.04 bash /mnt/c/Users/ASUS/Desktop/echo/start_vllm.sh`
  - `wsl -d Ubuntu-24.04 bash /mnt/c/Users/ASUS/Desktop/echo/start_gemma4_e2b_vllm.sh`
  - `cloudflared tunnel --url http://localhost:8002`
- [ ] Capture process output and show status in the desktop UI.
- [ ] Add health polling for ports `8002`, `8001`, and `8003`.
- [ ] Detect missing WSL, Python, cloudflared, or model files and show a specific fix.

### Backend

- [ ] Add a public pairing verification endpoint stronger than `/health`, for example `/pairing/info`.
- [ ] Return `{status, version, deviceName, pairingVersion}` from that endpoint.
- [ ] Add authenticated `/v1/system/health` response fields for tunnel readiness and model lane state.
- [ ] Consider adding a backend command endpoint only for desktop-local use, protected from tunnel access.

### Security

- [ ] Do not expose dangerous local process-start commands through the public tunnel.
- [ ] Require login/JWT for all private endpoints through the tunnel.
- [ ] Keep `/health` public, but make pairing verification non-sensitive.
- [ ] Prefer named Cloudflare tunnels or expiring pairing codes for production.
- [ ] Add a warning if the backend is using the default dev JWT secret before starting a tunnel.

### Packaging

- [ ] Verify `flutter run -d windows`.
- [ ] Verify `flutter build windows`.
- [ ] Create an Echo Desktop release folder.
- [ ] Decide whether backend scripts live beside the Flutter EXE or in a separate installer.
- [ ] Add a first-run setup wizard for dependencies.
- [ ] Add a download link or landing page from mobile onboarding.

## Acceptance Criteria

- A fresh Windows user can open Echo Desktop and see whether their home brain is ready.
- The desktop can show a QR code without the user manually copying a tunnel URL.
- Mobile can scan the QR from outside the home network.
- After pairing, mobile chat context/save/feedback/model fallback use the tunnel, not `10.0.2.2` or `localhost`.
- Lab on mobile shows the same system health as the desktop backend.
- If vLLM is off, the UI says that clearly instead of pretending pairing means the local model is ready.

