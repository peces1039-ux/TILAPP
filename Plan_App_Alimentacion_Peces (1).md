# 🐟 App de Alimentación de Peces - Documento de Implementación Completa

## 📘 Contexto General del Proyecto
Esta aplicación móvil está diseñada para optimizar y automatizar el **control de alimentación de peces en estanques**.  
El sistema permitirá registrar y analizar datos relacionados con la siembra, crecimiento, biometría y cantidad de alimento suministrado a los peces.

El propósito principal es ayudar a los acuicultores o administradores de estanques a **tomar decisiones informadas** sobre la alimentación y manejo de los peces, con base en datos precisos y actualizados.

---

## 🎯 Objetivos del Proyecto

### Objetivo General
Desarrollar una aplicación móvil que gestione el proceso de alimentación de peces mediante la recopilación de datos de siembra, biometría y estanques, generando una tabla de alimentación automática basada en los valores registrados.

### Objetivos Específicos
- Implementar una base de datos estructurada para el control de información.  
- Automatizar el cálculo del alimento requerido según peso y cantidad de peces.  
- Registrar y graficar datos de peso, tamaño y mortalidad.  
- Ofrecer un dashboard visual con indicadores del estado de los estanques.  
- Facilitar el seguimiento histórico de siembras y biometrías.  

---

## 📱 Estructura de la Aplicación

La aplicación contará con **6 pantallas principales**, cada una con un propósito funcional:

1. **Login:** acceso mediante usuario y contraseña.  
2. **Dashboard:** muestra gráficas del peso, cantidad y crecimiento de peces.  
3. **Estanques:** visualiza y gestiona el número y la capacidad de cada estanque.  
4. **Siembra:** registra especies, fechas, cantidades y mortalidad. Tiene llave foránea con *Estanques*.  
5. **Biometría:** almacena datos de fecha, peso promedio y tamaño promedio. Se relaciona con *Siembra*.  
6. **Plan de Alimentación:** genera una tabla automática de raciones de comida según los datos anteriores.  

Todas las pantallas incluirán una **barra de navegación inferior** para facilitar el desplazamiento entre módulos.

---

## 🧠 PARTE I: FASES LÓGICAS

### 📅 Fase 1: Análisis y Definición de Requerimientos
- Identificación de los procesos principales del sistema.  
- Definición de los módulos y sus relaciones.  
- Elaboración de diagramas de flujo y requerimientos técnicos.

### ⚙️ Fase 2: Diseño de la Arquitectura del Sistema
- Selección del modelo de arquitectura (MVC o por capas).  
- Definición de flujos de datos entre frontend y backend.  
- Especificación de los servicios o APIs requeridas.

### 🧩 Fase 3: Diseño de la Base de Datos
Tablas principales:
- Usuarios (para autenticación).  
- Estanques (id, capacidad, número).  
- Siembra (especie, fecha, cantidad, muertes, id_estanque FK).  
- Biometría (fecha, peso promedio, tamaño promedio, id_siembra FK).  
- Alimentación (cantidad, fecha, id_biometría FK).  

### 🧮 Fase 4: Lógica de Negocio y Funcionalidad Interna
- Cálculo de alimento según peso y cantidad.  
- CRUD completo de estanques, siembras, biometrías y alimentación.  
- Integridad de datos mediante llaves foráneas.

### 🧪 Fase 5: Validación Lógica
- Validación de cálculos y flujos de datos.  
- Comprobación de relaciones y consistencia.  

---

## 🎨 PARTE II: FASES DE DISEÑO Y DESARROLLO

### 🧱 Fase 6: Diseño UI/UX
- Creación de prototipos de las 6 pantallas principales.  
- Uso de colores azul, blanco y negro para estética marina.  
- Implementación de una barra inferior de navegación.  

### 💻 Fase 7: Desarrollo Frontend (Flutter)
- Programación de las pantallas en Flutter.  
- Integración de navegación y gráficos de datos.  
- Conexión con la base de datos.  

### 🧠 Fase 8: Integración Frontend–Backend
- Conexión de las funciones CRUD con Firebase o MySQL.  
- Validación de datos entre pantallas y módulos.  

### 🔍 Fase 9: Pruebas y Optimización
- Pruebas de rendimiento, seguridad y experiencia de usuario.  
- Corrección de errores y optimización de consumo de recursos.  

### 🚀 Fase 10: Despliegue y Mantenimiento
- Publicación en Google Play Store.  
- Creación de manual de usuario.  
- Establecimiento de plan de mantenimiento y mejoras.  

---

## 📊 Cronograma General

| Parte | Fase | Nombre | Duración | Semana |
|--------|------|---------|-----------|--------|
| **Lógica** | 1 | Análisis y Requerimientos | 1 semana | 1 |
|  | 2 | Diseño de Arquitectura | 1 semana | 2 |
|  | 3 | Diseño de Base de Datos | 1 semana | 3 |
|  | 4 | Lógica de Negocio | 2 semanas | 4–5 |
|  | 5 | Validación Lógica | 1 semana | 6 |
| **Diseño y Desarrollo** | 6 | Diseño UI/UX | 1 semana | 7 |
|  | 7 | Desarrollo Frontend | 3 semanas | 8–10 |
|  | 8 | Integración Front–Back | 1 semana | 11 |
|  | 9 | Pruebas Generales | 1 semana | 12 |
|  | 10 | Despliegue y Mantenimiento | 1 semana | 13 |

---

## ⏱ Duración Total del Proyecto
**13 semanas de implementación total.**  

**Resultado final:**  
Una app móvil integral para gestionar la alimentación de peces, con registro de estanques, siembras, biometrías y cálculo automático de alimento, desarrollada en Flutter y conectada a Firebase/MySQL.

---

© 2025 - Proyecto App de Alimentación de Peces | Danna Valentina Quintero Quintero
