#include <iostream>
#include <vector>

// Función para imprimir 
void imprimir(const std::vector<int>& v) {
    std::cout << "(";
    for (size_t i = 0; i < v.size(); i++) {
        if (i > 0) std::cout << " ";
        std::cout << v[i];
    }
    std::cout << ")\n";
}

std::vector<int> cuenta_atras(int n) {
    std::vector<int> resultado;
    for (int i = n; i > 0; i--) {
        resultado.push_back(i);
    }
    return resultado;
}

int main() {
    imprimir(cuenta_atras(5));
    imprimir(cuenta_atras(1));
    imprimir(cuenta_atras(0));
    return 0;
}
