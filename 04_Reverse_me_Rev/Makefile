
#!/usr/bin/make -f
# Makefile para 04_Reverse_me_Rev (ordenado y sin duplicados)

.PHONY: clean fclean help install-deps mandatory patch presentation run-originals run-patched test test-bonus

PYTHON := python3

.DEFAULT_GOAL := help

# Colores ANSI para presentación (consistente con otros Makefiles del repo)
NEGRITA     := \\033[1m
RESET       := \\033[0m
CIAN        := \\033[36m
VERDE       := \\033[32m
AMARILLO    := \\033[33m
ROJO        := \\033[31m
AZUL        := \\033[34m
MAGENTA     := \\033[35m

clean:
	@echo "$(NEGRITA)$(AMARILLO)[clean]$(RESET) Limpiando binarios parcheados..."
	@rm -f level1/level1_patched level2/level2_patched level2/level2_patched_failredir \
		 level3/level3_patched level3/level3_patched_failredir tutorial_auto.log level1/level1_recreated level2/level2_recreated level3/level3_recreated level1/*_recreated level2/*_recreated level3/*_recreated || true


fclean: clean
	@echo "$(NEGRITA)$(ROJO)[fclean]$(RESET) Limpieza completa (artefactos extra)"
	@rm -rf level1/*.o level2/*.o level3/*.o || true
	@rm -f compile_level*.log level3_rebuilt tutorial_auto.log || true


help:
	@echo "$(NEGRITA)$(CIAN)"
	@echo "┌────────────────────────────────────────────────────────┐"
	@echo "│       🧾 Reverse me — Makefile helper & verifier       │"
	@echo "└────────────────────────────────────────────────────────┘"
	@echo "$(RESET)"
	@echo "$(NEGRITA)Descripción:$(RESET) Proyecto Reverse — reproducciones de binarios y parches bonus"
	@echo ""
	@echo "  $(VERDE)make test$(RESET)            Ejecuta los binarios originales con las contraseñas incluidas"
	@echo "                       └─ Comprueba mandatory para level1/2/3"
	@echo ""
	@echo "  $(VERDE)make patch$(RESET)           Genera los patched binaries (usa patch_all.py)"
	@echo "                       └─ Produce level*/level*_patched"
	@echo ""
	@echo "  $(AMARILLO)make test-bonus$(RESET)      Ejecuta los patched y prueba con entrada arbitraria"
	@echo "                       └─ Verifica que los parches acepten cualquier input"
	@echo ""
	@echo "  $(AZUL)make run-originals$(RESET)   Ejecuta originals con las passwords incluidas"
	@echo "  $(AZUL)make run-patched$(RESET)     Ejecuta patched con ejemplo 'anything'"
	@echo ""
	@echo "  $(ROJO)make clean$(RESET)           Elimina patched generados"
	@echo "  $(ROJO)make fclean$(RESET)          Limpieza completa (artefactos extra)"
	@echo ""
	@echo "  $(MAGENTA)make presentation$(RESET)    Muestra cómo presentar el proyecto al evaluador"
	@echo "  $(MAGENTA)make tutorial$(RESET)        Abre el tutorial interactivo"
	@echo "  $(MAGENTA)make tutorial-auto$(RESET)   Ejecuta el tutorial sin pausas"
	@echo ""
	@echo "$(NEGRITA)$(CIAN)━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━$(RESET)"


install-deps:
	@echo "If you need to run 32-bit binaries on this host, install 32-bit libs."
	@echo "Debian/Ubuntu example: sudo dpkg --add-architecture i386 && sudo apt update && sudo apt install libc6:i386 libncurses5:i386 libstdc++6:i386"


# backwards-compatible alias
mandatory: test


patch:
	@echo "$(NEGRITA)$(VERDE)[patch]$(RESET) Applying patches (bonus) with patch_all.py..."
	@$(PYTHON) patch_all.py


presentation:
	@echo "$(NEGRITA)$(MAGENTA)===============================================$(RESET)"
	@echo "  $(NEGRITA)Reverse me — Project review & verification$(RESET)"
	@echo ""
	@echo "  $(VERDE)Mandatory:$(RESET) provide source.c + password for each level"
	@echo "  $(VERDE)Bonus:$(RESET) patches that accept any password (patch_all.py included)"
	@echo ""
	@echo "  $(AZUL)How to verify:$(RESET)"
	@echo "    $(VERDE)make test$(RESET)        # run originals with included passwords"
	@echo "    $(VERDE)make patch$(RESET)       # generate patched binaries (bonus)"
	@echo "    $(VERDE)make test-bonus$(RESET)  # run patched and verify any-input acceptance"
	@echo "$(NEGRITA)$(MAGENTA)===============================================$(RESET)"

# Tutorial helpers
.PHONY: tutorial tutorial-auto build-level1 build-level2

tutorial:
	@echo "$(NEGRITA)$(CIAN)[tutorial]$(RESET) Ejecutando tutorial (interactivo)"
	@./tutorial.sh

tutorial-auto:
	@echo "$(NEGRITA)$(CIAN)[tutorial-auto]$(RESET) Ejecutando tutorial en modo automático"
	@AUTO=1 ./tutorial.sh --auto

build-level1:
	@if [ -f level1/source.c ]; then mkdir -p level1 && gcc -o level1/level1_recreated level1/source.c; else echo "No hay level1/source.c"; fi

build-level2:
	@if [ -f level2/source.c ]; then mkdir -p level2 && gcc -o level2/level2_recreated level2/source.c; else echo "No hay level2/source.c"; fi


run-originals:
	@echo "$(NEGRITA)$(CIAN)[run-originals]$(RESET) Running original binaries with supplied passwords..."
	@printf "$(shell cat level1/password)\\n" | binary/level1 || true
	@printf "$(shell cat level2/password)\\n" | binary/level2 || true
	@printf "$(shell cat level3/password)\\n" | binary/level3 || true


run-patched:
	@echo "$(NEGRITA)$(CIAN)[run-patched]$(RESET) Testing patched binaries with example input 'anything'..."
	@printf "anything\\n" | level1/level1_patched || true
	@printf "anything\\n" | level2/level2_patched || true
	@printf "anything\\n" | level3/level3_patched || true


test: run-originals


test-bonus: patch run-patched

