# Google Maps API Key — instrukcja utworzenia

> Potrzebne dla S-06 (map picker w dialogu dodawania atrakcji). Klucz jest darmowy — Maps SDK for Android ma unlimited free tier od marca 2025.

## Krok 1: Wejdź do Google Cloud Console

Otwórz https://console.cloud.google.com/ i zaloguj się tym samym kontem Google, którego używasz do Firebase (travelapp-d22a9).

## Krok 2: Wybierz projekt Firebase

Na górze strony, obok logo Google Cloud, kliknij nazwę projektu i wybierz **travelapp-d22a9** (to ten sam projekt co Firebase).

## Krok 3: Włącz Maps SDK for Android

1. W lewym menu przejdź do **APIs & Services** → **Library**
2. Wyszukaj **"Maps SDK for Android"**
3. Kliknij i naciśnij **ENABLE**

Jeśli zobaczysz "Maps SDK for Android is already enabled" — przejdź do kroku 4.

## Krok 4: Utwórz API key

1. W lewym menu przejdź do **APIs & Services** → **Credentials**
2. Kliknij **+ CREATE CREDENTIALS** → **API key**
3. Skopiuj wygenerowany klucz (zaczyna się od `AIzaSy...`)

## Krok 5: (Zalecane) Ogranicz klucz do swojej aplikacji

1. Na liście credentials kliknij nazwę nowego klucza (albo ikonę ołówka)
2. W sekcji **API restrictions** wybierz **Restrict key** i z listy wybierz tylko **Maps SDK for Android**
3. W sekcji **Application restrictions** wybierz **Android apps** i dodaj:
   - Nazwa pakietu: `pl.bemowski.trekjot`
   - Odcisk SHA-1: (na razie pomiń — możesz dodać później dla release)

> ⚠️ Bez RESTRICTIONS klucz działa dla każdej aplikacji. Ograniczenie do Androida + tylko Maps SDK zabezpiecza przed kradzieżą.

## Krok 6: Dodaj klucz lokalnie

W katalogu `android/app/` projektu utwórz lub edytuj plik `local.properties`:

```properties
MAPS_API_KEY=AIzaSy...twój_klucz...
```

> Ten plik jest w `.gitignore` — nie trafi do repo.

## Krok 7: Dodaj klucz do GitHub Secrets (dla CI)

1. Wejdź na https://github.com/kamilbemowski/traveljug/settings/secrets/actions
2. Kliknij **New repository secret**
3. Name: `MAPS_API_KEY`
4. Secret: wklej ten sam klucz `AIzaSy...`
5. Kliknij **Add secret**

## Krok 8: Przetestuj

```bash
flutter run
```

Otwórz dialog dodawania atrakcji, kliknij "Add location (optional)" → "Pick on map". Powinna otworzyć się pełnoekranowa mapa Google. Kliknij gdziekolwiek → pojawi się znacznik → Confirm → współrzędne wypełnią formularz.

Jeśli mapa się nie ładuje (szare tło), sprawdź:
- Czy `MAPS_API_KEY` jest w `android/app/local.properties`
- Czy Maps SDK for Android jest włączony w Google Cloud Console
- Czy zrobiłeś `flutter clean && flutter pub get` i restart aplikacji

## Koszt

**$0** — Maps SDK for Android jest całkowicie darmowy (unlimited free tier od marca 2025). Nie potrzebujesz podpinać billing.
