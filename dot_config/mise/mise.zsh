# ============================================
# mise 配置 - 独立控制开关
# ============================================

# 自定义开关
export MY_DISABLE_PYTHON=1
export MY_DISABLE_NODE=1
export MY_DISABLE_BUN=1
export MY_DISABLE_JAVA=1
export MY_DISABLE_GO=1

# 激活 mise
# eval "$(mise activate zsh)" 前面已有激活

# ============================================
# 核心函数：根据开关更新 MISE_DISABLE_TOOLS
# ============================================

mise-update-disable-tools() {
    local tools=""
    
    [ -n "$MY_DISABLE_PYTHON" ] && tools="python"
    [ -n "$MY_DISABLE_NODE" ] && tools="${tools:+$tools,}node"
    [ -n "$MY_DISABLE_BUN" ] && tools="${tools:+$tools,}bun"
    [ -n "$MY_DISABLE_JAVA" ] && tools="${tools:+$tools,}java"
    [ -n "$MY_DISABLE_GO" ] && tools="${tools:+$tools,}go"
    
    if [ -n "$tools" ]; then
        export MISE_DISABLE_TOOLS="$tools"
    else
        unset MISE_DISABLE_TOOLS
    fi
}

# 初始化
mise-update-disable-tools

# ============================================
# mise 函数包装
# ============================================

mise() {
    local cmd="$1"
    shift
    
    # 保存当前禁用状态
    local original_python="$MY_DISABLE_PYTHON"
    local original_node="$MY_DISABLE_NODE"
    local original_bun="$MY_DISABLE_BUN"
    local original_java="$MY_DISABLE_JAVA"
    local original_go="$MY_DISABLE_GO"
    
    if [ "$cmd" = "list" ]; then
        # 临时解禁所有工具
        unset MY_DISABLE_PYTHON MY_DISABLE_NODE MY_DISABLE_BUN MY_DISABLE_JAVA MY_DISABLE_GO
        mise-update-disable-tools
        echo "📋 临时解禁所有工具以显示完整列表..."
    elif [ "$cmd" = "use" ]; then
        # 检测 python
        if echo "$@" | grep -qE "^python(@|[[:space:]]|$)"; then
            if [ -n "$MY_DISABLE_PYTHON" ]; then
                unset MY_DISABLE_PYTHON
                mise-update-disable-tools
                echo "⚡ 启用 Python 管理"
            fi
        fi
        
        # 检测 node
        if echo "$@" | grep -qE "^node(@|[[:space:]]|$)"; then
            if [ -n "$MY_DISABLE_NODE" ]; then
                unset MY_DISABLE_NODE
                mise-update-disable-tools
                echo "⚡ 启用 Node 管理"
            fi
        fi
        
        # 检测 bun
        if echo "$@" | grep -qE "^bun(@|[[:space:]]|$)"; then
            if [ -n "$MY_DISABLE_BUN" ]; then
                unset MY_DISABLE_BUN
                mise-update-disable-tools
                echo "⚡ 启用 Bun 管理"
            fi
        fi
        
        # 检测 java
        if echo "$@" | grep -qE "^java(@|[[:space:]]|$)"; then
            if [ -n "$MY_DISABLE_JAVA" ]; then
                unset MY_DISABLE_JAVA
                mise-update-disable-tools
                echo "⚡ 启用 Java 管理"
            fi
        fi
        
        # 检测 go
        if echo "$@" | grep -qE "^go(@|[[:space:]]|$)"; then
            if [ -n "$MY_DISABLE_GO" ]; then
                unset MY_DISABLE_GO
                mise-update-disable-tools
                echo "⚡ 启用 Go 管理"
            fi
        fi
    fi
    
    # 执行原始命令
    command mise "$cmd" "$@"
    
    # 如果是list命令，恢复原来的禁用状态
    if [ "$cmd" = "list" ]; then
        # 恢复原来的禁用状态
        [ -n "$original_python" ] && export MY_DISABLE_PYTHON=1 || unset MY_DISABLE_PYTHON
        [ -n "$original_node" ] && export MY_DISABLE_NODE=1 || unset MY_DISABLE_NODE
        [ -n "$original_bun" ] && export MY_DISABLE_BUN=1 || unset MY_DISABLE_BUN
        [ -n "$original_java" ] && export MY_DISABLE_JAVA=1 || unset MY_DISABLE_JAVA
        [ -n "$original_go" ] && export MY_DISABLE_GO=1 || unset MY_DISABLE_GO
        mise-update-disable-tools
        echo "🔒 已恢复原来的工具禁用状态"
    fi
}

# ============================================
# 手动控制函数
# ============================================

mise-python-enable() {
    unset MY_DISABLE_PYTHON
    mise-update-disable-tools
    echo "✅ Python 管理已启用"
}

mise-python-disable() {
    export MY_DISABLE_PYTHON=1
    mise-update-disable-tools
    echo "🚫 Python 管理已禁用"
}

mise-node-enable() {
    unset MY_DISABLE_NODE
    mise-update-disable-tools
    echo "✅ Node 管理已启用"
}

mise-node-disable() {
    export MY_DISABLE_NODE=1
    mise-update-disable-tools
    echo "🚫 Node 管理已禁用"
}

mise-bun-enable() {
    unset MY_DISABLE_BUN
    mise-update-disable-tools
    echo "✅ Bun 管理已启用"
}

mise-bun-disable() {
    export MY_DISABLE_BUN=1
    mise-update-disable-tools
    echo "🚫 Bun 管理已禁用"
}

# Java 控制函数
mise-java-enable() {
    unset MY_DISABLE_JAVA
    mise-update-disable-tools
    echo "✅ Java 管理已启用"
}

mise-java-disable() {
    export MY_DISABLE_JAVA=1
    mise-update-disable-tools
    echo "🚫 Java 管理已禁用"
}

# Go 控制函数
mise-go-enable() {
    unset MY_DISABLE_GO
    mise-update-disable-tools
    echo "✅ Go 管理已启用"
}

mise-go-disable() {
    export MY_DISABLE_GO=1
    mise-update-disable-tools
    echo "🚫 Go 管理已禁用"
}

mise-status() {
    echo "=== mise 状态 ==="
    [ -n "$MY_DISABLE_PYTHON" ] && echo "🚫 Python: 禁用" || echo "✅ Python: 启用"
    [ -n "$MY_DISABLE_NODE" ] && echo "🚫 Node:   禁用" || echo "✅ Node:   启用"
    [ -n "$MY_DISABLE_BUN" ] && echo "🚫 Bun:    禁用" || echo "✅ Bun:    启用"
    [ -n "$MY_DISABLE_JAVA" ] && echo "🚫 Java:   禁用" || echo "✅ Java:   启用"
    [ -n "$MY_DISABLE_GO" ] && echo "🚫 Go:     禁用" || echo "✅ Go:     启用"
    echo ""
    echo "MISE_DISABLE_TOOLS=${MISE_DISABLE_TOOLS:-<unset>}"
    echo ""
    echo "Python: $(which python 2>/dev/null)"
    echo "Node:   $(which node 2>/dev/null)"
    echo "Bun:    $(which bun 2>/dev/null)"
    echo "Java:   $(which java 2>/dev/null)"
    echo "Go:     $(which go 2>/dev/null)"
}