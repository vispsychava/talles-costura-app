import 'package:flutter/material.dart';

class ConfiguracionScreen extends StatelessWidget {
  const ConfiguracionScreen({
    super.key,
  });

  void _mostrarMensaje(BuildContext context, String label) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '¡Configuración de "$label" disponible en la versión de producción!',
        ),
        backgroundColor: const Color(0xff6D3EFF),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF8FAFC),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Ajustes del Sistema",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xff102A43),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PERFIL
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      const CircleAvatar(
                        radius: 45,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=32",
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xff6D3EFF),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.verified,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Doña Tere",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff102A43),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Diseñadora de Alta Costura & Administradora",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xff64748B),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xff6D3EFF).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: const Color(0xff6D3EFF).withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.workspace_premium,
                              size: 16,
                              color: Color(0xff6D3EFF),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "PREMIUM TAILOR",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff6D3EFF),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(
                              Icons.verified_user,
                              size: 16,
                              color: Color(0xff475569),
                            ),
                            SizedBox(width: 6),
                            Text(
                              "OWNER",
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff475569),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// OPCIONES
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _itemConfiguracion(
                    context,
                    icon: Icons.storefront,
                    titulo: "Datos de Taller",
                    subtitulo: "Dirección corporativa, teléfonos públicos y logotipos",
                    onTap: () => _mostrarMensaje(
                      context,
                      "Datos de Taller",
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemConfiguracion(
                    context,
                    icon: Icons.lock,
                    titulo: "Contraseña y Seguridad",
                    subtitulo: "Actualiza tus claves de acceso de administrador",
                    onTap: () => _mostrarMensaje(
                      context,
                      "Contraseña y Seguridad",
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemConfiguracion(
                    context,
                    icon: Icons.cloud_upload,
                    titulo: "Respaldo Automático",
                    subtitulo: "Sincronización automática de órdenes en la nube",
                    onTap: () => _mostrarMensaje(
                      context,
                      "Respaldo Automático",
                    ),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _itemConfiguracion(
                    context,
                    icon: Icons.info_outline,
                    titulo: "Acerca de la Aplicación",
                    subtitulo: "Versión 2.4.1",
                    onTap: () => _mostrarMensaje(
                      context,
                      "Acerca de la Aplicación",
                    ),
                  ),
                  // ✅ ELIMINADO: Cerrar Sesión
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemConfiguracion(
    BuildContext context, {
    required IconData icon,
    required String titulo,
    required String subtitulo,
    required VoidCallback onTap,
  }) {
    final color = const Color(0xff6D3EFF);
    final bgColor = color.withValues(alpha: 0.08);

    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: color,
          size: 24,
        ),
      ),
      title: Text(
        titulo,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
          color: Color(0xff102A43),
        ),
      ),
      subtitle: Text(
        subtitulo,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xff64748B),
        ),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        color: Color(0xff829AB1),
      ),
      onTap: onTap,
    );
  }
}