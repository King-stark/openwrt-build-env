FROM ubuntu:20.04

ARG USER=user
ARG DEBIAN_FRONTEND noninteractive

RUN apt-get -y update && apt-get -y upgrade \
    && apt-get install -y curl sudo zsh htop byobu tree ca-certificates uuid-runtime tzdata xz-utils openssh-server \
    && apt-get install -y $(curl -fsSL https://github.com/King-stark/Build-OpenWrt/raw/main/depends/depends-lede) \
    && ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && apt-get autoremove --purge \
    && apt-get autoclean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /root/.cache/* \
    && mkdir /var/run/sshd \
    && rm -f /etc/ssh/ssh_host_*key* 

ENV LANG en_US.utf8

RUN groupadd -g 1000 $USER \
    && useradd -l -m -d /home/user -u 1000 -g $USER -G sudo -s $(which zsh) $USER \
    && echo "$USER:$USER" | chpasswd \
    && sed -ri 's/UsePAM yes/#UsePAM yes/g' /etc/ssh/sshd_config \
    && echo "$USER ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/$USER \
    && chmod 440 /etc/sudoers.d/$USER \
    && mkdir -p ~/.ssh \
    && chmod 700 ~/.ssh

USER user
WORKDIR /home/user
ENV TERM=xterm-256color

RUN CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" \
    && sed -i 's/ZSH_THEME="robbyrussell"/ZSH_THEME="ys"/' ~/.zshrc \
    && git clone https://github.com/zsh-users/zsh-completions ${ZSH_CUSTOM:=~/.oh-my-zsh/custom}/plugins/zsh-completions \
    && git clone https://github.com/zsh-users/zsh-history-substring-search ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-history-substring-search \
    && git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting \
    && git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions \
    && sed -i 's/plugins=(git)/plugins=(git extract sudo zsh-syntax-highlighting zsh-completions history-substring-search zsh-autosuggestions)\nautoload -U compinit \&\& compinit/g' ~/.zshrc

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]
