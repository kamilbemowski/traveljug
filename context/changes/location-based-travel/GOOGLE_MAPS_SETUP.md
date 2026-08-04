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

## Krok 5: Ogranicz klucz TYLKO do swojej aplikacji

To najważniejszy krok bezpieczeństwa. Nawet jeśli klucz wycieknie, nie zadziała w innej aplikacji.

### 5a: Ograniczenie do Androida

1. Na liście credentials kliknij nazwę swojego klucza (lub ikonę ołówka)
2. W sekcji **Application restrictions** wybierz **Android apps**
3. Kliknij **+ Add package name and fingerprint**
4. Wpisz:
   - **Package name**: `pl.bemowski.trekjot`
   - **SHA-1 certificate fingerprint**: (patrz niżej jak uzyskać)

### 5b: Pobierz SHA-1 fingerprint

**Dla debug build (local dev):**
```bash
cd android
./gradlew signingReport | grep -A1 "SHA1" | head -2
```
Albo jeśli nie działa:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android | grep SHA1
```

**Dla release build (CI):** ten sam fingerprint co w keystore używanym przez CI. Jeśli masz osobny keystore, użyj:
```bash
keytool -list -v -keystore <ścieżka/do/keystore.jks> -alias upload | grep SHA1
```

> Możesz dodać oba odciski (debug + release) — Google pozwala na wiele fingerprintów dla jednego klucza.

### 5c: Ograniczenie do Maps SDK

1. W tym samym oknie edycji klucza, sekcja **API restrictions**
2. Wybierz **Restrict key**
3. Z rozwijanej listy wybierz tylko **Maps SDK for Android**
4. Kliknij **Save**

Po zapisaniu:
- ✅ Klucz działa tylko w aplikacji `pl.bemowski.trekjot`
- ✅ Klucz działa tylko dla Maps SDK (nie dla Geocoding, Directions itp.)
- ✅ Nawet jeśli klucz wycieknie, nie da się go użyć w innej apce ani do innych API

## Krok 6: Limit wydatków (budget alert)

Maps SDK for Android jest **całkowicie darmowy** (unlimited free tier). Nie da się nim wygenerować kosztów. Ale na wszelki wypadek — gdyby ktoś dodał inne płatne API do tego samego projektu — ustawiamy alert:

1. W Google Cloud Console, lewe menu → **Billing**
2. Jeśli nie masz podpiętego konta billingowego, przejdź do **Billing** i kliknij **Link a billing account** (możesz użyć darmowego konta)
3. Po podpięciu, przejdź do **Budgets & alerts**
4. Kliknij **Create budget**
5. Ustaw:
   - **Name**: `TravelJug monthly cap`
   - **Amount**: `5 USD` (ok. 20 PLN)
   - **Scope**: `All services in travelapp-d22a9`
   - ✅ **Email alerts**: 50%, 90%, 100%
6. Kliknij **Save**

> ⚠️ Samo podpięcie billing nie oznacza kosztów — Maps SDK ma unlimited free tier. Alert to siatka bezpieczeństwa na wypadek gdyby ktoś włączył płatne API w przyszłości.

## Krok 7: Dodaj klucz lokalnie

W katalogu `android/app/` projektu utwórz lub edytuj plik `local.properties`:

```properties
MAPS_API_KEY=AIzaSy...twój_klucz...
```

> Ten plik jest w `.gitignore` — nie trafi do repo.

## Krok 8: Dodaj klucz do GitHub Secrets (dla CI)

1. Wejdź na https://github.com/kamilbemowski/traveljug/settings/secrets/actions
2. Kliknij **New repository secret**
3. Name: `MAPS_API_KEY`
4. Secret: wklej ten sam klucz `AIzaSy...`
5. Kliknij **Add secret**

## Krok 9: Przetestuj

```bash
flutter run
```

Otwórz dialog dodawania atrakcji, kliknij "Add location (optional)" → "Pick on map". Powinna otworzyć się pełnoekranowa mapa Google. Kliknij gdziekolwiek → pojawi się znacznik → Confirm → współrzędne wypełnią formularz.

Jeśli mapa się nie ładuje (szare tło), sprawdź:
- Czy `MAPS_API_KEY` jest w `android/app/local.properties`
- Czy Maps SDK for Android jest włączony w Google Cloud Console
- Czy zrobiłeś `flutter clean && flutter pub get` i restart aplikacji

## Koszt

**$0** — Maps SDK for Android jest całkowicie darmowy (unlimited free tier od marca 2025). Jedyne API którego używamy. Nawet przy milionie wyświetleń mapy miesięcznie — koszt to zero. Budget alert z Kroku 6 to czysta asekuracja na wypadek dodania innych API w przyszłości.
