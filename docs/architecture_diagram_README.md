This repository includes a Mermaid architecture diagram source at `docs/architecture_diagram.mmd`.

To render a PNG locally, you can use one of these options.

Option A: npx mermaid-cli

```bash
# install once
npm install -g @mermaid-js/mermaid-cli
# render PNG
mmdc -i docs/architecture_diagram.mmd -o docs/architecture_diagram.png -t default
```

Option B: npx (no global install)

```bash
npx @mermaid-js/mermaid-cli -i docs/architecture_diagram.mmd -o docs/architecture_diagram.png
```

Option C: Docker

```bash
docker run --rm -v "$PWD":/data minlag/mermaid-cli -i /data/docs/architecture_diagram.mmd -o /data/docs/architecture_diagram.png
```

Notes:
- If you prefer SVG, change the output filename extension to `.svg`.
- If you want me to attempt to render the PNG here, tell me and I'll try, but I may be unable to run Docker or npm in this environment.
