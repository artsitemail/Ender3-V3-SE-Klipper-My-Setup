#!/bin/bash
# =============================================================
# cache_cores.sh — Lê as cores do ficheiro em impressão via
# Moonraker e envia-as ao Klipper como variável da macro.
# Chamado por CACHE_CORES em PRINT_START.
# =============================================================

FILEPATH="$1"

# Extrai a linha de cores do cabeçalho do gcode (OrcaSlicer format)
CORES_HEX=$(grep -m1 "; filament_colour" "$FILEPATH" 2>/dev/null \
            | sed 's/.*= *//' | tr -d ' \r\n')

# Extrai os tipos de filamento (PLA, PETG, etc.)
TIPOS=$(grep -m1 "; filament_type" "$FILEPATH" 2>/dev/null \
        | sed 's/.*= *//' | tr -d ' \r\n')

# Converte hex → nome legível com Python
NOMES=$(python3 - "$CORES_HEX" "$TIPOS" << 'PYEOF'
import sys

def hex_to_nome(h):
    h = h.strip().lstrip('#')
    if len(h) != 6:
        return h if h else "Desconhecida"
    try:
        r,g,b = int(h[0:2],16), int(h[2:4],16), int(h[4:6],16)
    except:
        return h
    # Mapeamento simples por canal dominante
    if r>220 and g>220 and b>220: return "Branco"
    if r<40  and g<40  and b<40:  return "Preto"
    if r>180 and g<80  and b<80:  return "Vermelho"
    if r<80  and g>160 and b<80:  return "Verde"
    if r<80  and g<80  and b>180: return "Azul"
    if r>200 and g>180 and b<80:  return "Amarelo"
    if r>210 and g>90  and b<70:  return "Laranja"
    if r>130 and g<80  and b>130: return "Roxo"
    if r>180 and g<80  and b>100: return "Rosa"
    if r>130 and g>70  and b<60:  return "Castanho"
    if r>100 and g>100 and b>100: return "Cinza"
    return "#" + h.upper()         # fallback: mostra o hex

cores_hex  = sys.argv[1].split(';') if sys.argv[1] else []
tipos      = sys.argv[2].split(';') if len(sys.argv) > 2 and sys.argv[2] else []

resultado = []
for i, hex_c in enumerate(cores_hex):
    nome  = hex_to_nome(hex_c)
    tipo  = tipos[i].strip() if i < len(tipos) else ""
    label = f"{tipo} {nome}".strip() if tipo else nome
    resultado.append(label)

print(','.join(resultado))
PYEOF
)

if [ -z "$NOMES" ]; then
    NOMES="Cor 1,Cor 2,Cor 3,Cor 4,Cor 5,Cor 6,Cor 7,Cor 8,Cor 9,Cor 10"
fi

# Envia as cores de volta ao Klipper via Moonraker API
curl -s -X POST "http://localhost:7125/printer/gcode/script" \
     -H "Content-Type: application/json" \
     -d "{\"script\": \"_SET_CORES CORES=\\\"${NOMES}\\\"\"}" \
     > /dev/null 2>&1

exit 0
