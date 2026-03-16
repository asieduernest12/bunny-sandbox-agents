FROM oven/bun:slim

RUN apt update;apt upgrade -yf; 
RUN apt install -yf  make tmux tree nano curl unzip docker-cli docker-compose bash git starship procps
RUN bun i -g openclaw opencode-ai @kilocode/cli @google/gemini-cli @anthropic-ai/claude-code @musistudio/claude-code-router

ENV FNM_DIR=/opt/fnm

RUN curl -fsSL https://fnm.vercel.app/install | bash -s -- --install-dir "/opt/fnm" --skip-shell ;
RUN echo '\nexport FNM_DIR=/opt/fnm' >> /etc/bash.bashrc;\
    echo '\nexport PATH="$FNM_DIR:$PATH"' >> /etc/bash.bashrc;\
    echo '\neval "$($FNM_DIR/fnm env --shell bash)"' >> /etc/bash.bashrc 


RUN $FNM_DIR/fnm i 24 && $FNM_DIR/fnm default 24
