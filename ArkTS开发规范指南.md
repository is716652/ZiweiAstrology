# ArkTS 开发规范指南

## 概述
本文档总结了HarmonyOS ArkTS语言的核心规范和限制，帮助开发者在项目开发过程中避免常见的编译错误。

## 🚫 核心禁用规则

### 1. 类型系统限制

#### 禁止使用的类型
- `any` 类型：完全禁止使用
- `unknown` 类型：不允许使用
- 索引签名：`[key: string]: T` 语法禁止
- 对象字面量类型：`{ name: string, age: number }` 内联类型定义禁止

#### ❌ 错误示例
```typescript
// 禁止使用any
let data: any = { name: "test" };

// 禁止使用索引签名
interface User {
  [key: string]: string; // ❌ 错误
}

// 禁止内联对象字面量类型
function processUser(user: { name: string, age: number }) { // ❌ 错误
  // ...
}
```

#### ✅ 正确做法
```typescript
// 定义明确的接口
interface User {
  name: string;
  age: number;
}

let data: User = { name: "test", age: 25 };

function processUser(user: User) { // ✅ 正确
  // ...
}
```

### 2. 循环语句限制

#### 禁止的循环方式
- `for...in` 循环：用于对象遍历时禁止
- `for...of` 循环：用于对象遍历时禁止

#### ❌ 错误示例
```typescript
const obj = { a: 1, b: 2, c: 3 };

// 禁止用于对象
for (const key in obj) { // ❌ 错误
  console.log(key, obj[key]);
}

for (const value of obj) { // ❌ 错误
  console.log(value);
}
```

#### ✅ 正确做法
```typescript
const obj = { a: 1, b: 2, c: 3 };

// 使用传统循环遍历对象键
const keys = Object.keys(obj);
for (let i = 0; i < keys.length; i++) {
  const key = keys[i];
  console.log(key, obj[key as keyof typeof obj]);
}

// 数组可以使用for...of
const arr = [1, 2, 3];
for (const item of arr) { // ✅ 数组可以使用
  console.log(item);
}
```

### 3. 属性访问限制

#### 禁止动态索引访问
- `obj[key]` 语法禁止
- 必须使用明确的属性名或类型安全的访问方式

#### ❌ 错误示例
```typescript
const user = { name: "张三", age: 25 };
const propertyName = "name";

// 禁止动态索引访问
const value = user[propertyName]; // ❌ 错误
```

#### ✅ 正确做法
```typescript
interface User {
  name: string;
  age: number;
}

const user: User = { name: "张三", age: 25 };
const propertyName = "name";

// 使用switch语句或类型断言
let value: string | number;
switch (propertyName) {
  case "name":
    value = user.name;
    break;
  case "age":
    value = user.age;
    break;
  default:
    value = "";
}

// 或使用Map
const userMap = new Map<string, string | number>();
userMap.set("name", "张三");
userMap.set("age", 25);
const mapValue = userMap.get(propertyName);
```

### 4. 对象处理限制

#### 禁止未类型化的对象字面量
- 所有对象必须预先定义接口
- 不允许使用隐式类型推断的对象

#### ❌ 错误示例
```typescript
// 禁止未类型化的对象字面量
const config = {
  api: "https://api.example.com",
  timeout: 5000
}; // ❌ 错误

function createData() {
  return { id: 1, name: "test" }; // ❌ 错误
}
```

#### ✅ 正确做法
```typescript
// 定义接口
interface Config {
  api: string;
  timeout: number;
}

interface Data {
  id: number;
  name: string;
}

const config: Config = {
  api: "https://api.example.com",
  timeout: 5000
}; // ✅ 正确

function createData(): Data {
  return { id: 1, name: "test" }; // ✅ 正确
}
```

## 📝 推荐替代方案

### 1. 使用Map/Record替代动态对象

#### 传统对象方式（❌ 禁止）
```typescript
const dynamicData: { [key: string]: string } = {};
dynamicData["field1"] = "value1";
```

#### Map方式（✅ 推荐）
```typescript
const dynamicData = new Map<string, string>();
dynamicData.set("field1", "value1");
const value = dynamicData.get("field1");
```

#### Record方式（✅ 推荐）
```typescript
type StringRecord = Record<string, string>;
const data: StringRecord = {
  field1: "value1",
  field2: "value2"
};
```

### 2. 使用传统循环

#### ❌ 禁止方式
```typescript
const obj = { a: 1, b: 2 };
for (const key in obj) {
  console.log(obj[key]);
}
```

#### ✅ 推荐方式
```typescript
const obj = { a: 1, b: 2 };
const keys = Object.keys(obj);
for (let i = 0; i < keys.length; i++) {
  const key = keys[i];
  console.log(obj[key as keyof typeof obj]);
}
```

### 3. 明确接口定义

#### ❌ 内联类型（禁止）
```typescript
function process(data: { name: string, value: number }) {
  // ...
}
```

#### ✅ 预定义接口（推荐）
```typescript
interface DataItem {
  name: string;
  value: number;
}

function process(data: DataItem) {
  // ...
}
```

## 🚫 更多核心限制

### 5. 函数和方法限制

#### 禁止的语法特性
- 解构赋值：`const [a, b] = array;` 禁止
- 展开运算符：`const newArr = [...arr];` 禁止
- 可选链操作符：`obj?.property` 禁止
- 空值合并操作符：`value ?? defaultValue` 禁止

#### ❌ 错误示例
```typescript
// 解构赋值
const [name, age] = userData; // ❌ 错误

// 展开运算符
const combined = { ...obj1, ...obj2 }; // ❌ 错误
const newArray = [...oldArray, newItem]; // ❌ 错误

// 可选链
const value = obj?.prop?.subProp; // ❌ 错误

// 空值合并
const result = value ?? default; // ❌ 错误
```

#### ✅ 正确做法
```typescript
// 替代解构赋值
const name = userData[0];
const age = userData[1];

// 替代对象展开
const combined: CombinedType = {
  prop1: obj1.prop1,
  prop2: obj2.prop2
};

// 替代数组展开
const newArray: ItemType[] = [];
for (let i = 0; i < oldArray.length; i++) {
  newArray.push(oldArray[i]);
}
newArray.push(newItem);

// 替代可选链
let value: ValueType;
if (obj && obj.prop && obj.prop.subProp) {
  value = obj.prop.subProp;
}

// 替代空值合并
let result: ResultType;
if (value !== null && value !== undefined) {
  result = value;
} else {
  result = default;
}
```

### 6. 静态方法限制

#### 静态上下文中的this使用
- 静态方法中不能使用 `this` 访问实例属性
- 静态方法中调用其他静态方法必须使用 `ClassName.method()`

#### ❌ 错误示例
```typescript
class DataManager {
  private static data: string[] = [];
  
  static addItem(item: string): void {
    this.data.push(item); // ❌ 错误：静态方法中使用this
    this.processData(); // ❌ 错误
  }
  
  static processData(): void {
    // 处理逻辑
  }
}
```

#### ✅ 正确做法
```typescript
class DataManager {
  private static data: string[] = [];
  
  static addItem(item: string): void {
    DataManager.data.push(item); // ✅ 正确
    DataManager.processData(); // ✅ 正确
  }
  
  static processData(): void {
    // 处理逻辑
  }
  
  static getData(): string[] {
    return DataManager.data; // ✅ 正确
  }
}
```

### 7. 类型推断限制

#### 必须显式类型注解的场景
- 函数返回值类型
- 变量声明（特别是复杂类型）
- 类属性定义

#### ❌ 错误示例
```typescript
// 缺少返回类型注解
function createUser(name: string) { // ❌ 错误
  return { name: name, id: Math.random() };
}

// 复杂对象缺少类型
const user = { // ❌ 错误
  name: "张三",
  profile: {
    age: 25,
    email: "zhang@example.com"
  }
};
```

#### ✅ 正确做法
```typescript
interface User {
  name: string;
  id: number;
}

interface UserProfile {
  age: number;
  email: string;
}

interface CompleteUser {
  name: string;
  profile: UserProfile;
}

function createUser(name: string): User { // ✅ 正确
  return { name: name, id: Math.random() };
}

const user: CompleteUser = { // ✅ 正确
  name: "张三",
  profile: {
    age: 25,
    email: "zhang@example.com"
  }
};
```

## 🛠️ 实用技巧

### 1. 快速错误定位
- 根据编译错误代码快速识别问题类型
- 常见错误代码对应特定规范违反

### 2. 类型安全优先
- 优先使用类型安全的API和方法
- 避免类型断言，使用类型守卫

### 3. 清晰的接口层次
- 为所有数据结构定义明确的接口
- 使用接口继承构建类型层次

### 4. 枚举和联合类型
```typescript
// 使用枚举提高可读性
enum Status {
  Active = "active",
  Inactive = "inactive"
}

// 使用联合类型限制取值范围
type Theme = "light" | "dark" | "auto";
```

### 5. 工具类和辅助方法
```typescript
// 数组操作工具类
class ArrayUtils {
  static clone<T>(source: T[]): T[] {
    const result: T[] = [];
    for (let i = 0; i < source.length; i++) {
      result.push(source[i]);
    }
    return result;
  }
  
  static find<T>(items: T[], predicate: (item: T) => boolean): T | undefined {
    for (let i = 0; i < items.length; i++) {
      if (predicate(items[i])) {
        return items[i];
      }
    }
    return undefined;
  }
}

// 对象操作工具类
class ObjectUtils {
  static merge<T>(target: T, source: Partial<T>): T {
    const result: T = { ...target };
    const keys = Object.keys(source) as (keyof T)[];
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      const sourceValue = source[key];
      if (sourceValue !== undefined) {
        result[key] = sourceValue;
      }
    }
    return result;
  }
}
```

## 🎯 常见场景解决方案

### 1. 动态属性访问

#### 场景：根据字符串键访问对象属性
```typescript
interface User {
  name: string;
  age: number;
  email: string;
}

function getProperty(obj: User, key: string): string | number {
  switch (key) {
    case "name":
      return obj.name;
    case "age":
      return obj.age;
    case "email":
      return obj.email;
    default:
      throw new Error(`Unknown property: ${key}`);
  }
}
```

### 2. 数组对象处理

#### 场景：处理对象数组
```typescript
interface Item {
  id: number;
  name: string;
}

function findItem(items: Item[], id: number): Item | undefined {
  for (let i = 0; i < items.length; i++) {
    if (items[i].id === id) {
      return items[i];
    }
  }
  return undefined;
}
```

### 3. 配置对象管理

#### 场景：应用配置管理
```typescript
interface AppConfig {
  apiUrl: string;
  timeout: number;
  retries: number;
}

class ConfigManager {
  private static config: AppConfig = {
    apiUrl: "",
    timeout: 5000,
    retries: 3
  };

  static getConfig(): AppConfig {
    return ConfigManager.config;
  }

  static updateConfig(newConfig: Partial<AppConfig>): void {
    ConfigManager.config = ObjectUtils.merge(ConfigManager.config, newConfig);
  }
}
```

### 4. 状态管理模式

#### 场景：组件状态管理
```typescript
interface StateData {
  isLoading: boolean;
  data: string[];
  error: string | null;
}

class StateManager {
  private static state: StateData = {
    isLoading: false,
    data: [],
    error: null
  };

  static getState(): StateData {
    return { ...StateManager.state };
  }

  static setLoading(loading: boolean): void {
    StateManager.state.isLoading = loading;
  }

  static setData(newData: string[]): void {
    StateManager.state.data = newData;
    StateManager.state.error = null;
  }

  static setError(error: string): void {
    StateManager.state.error = error;
    StateManager.state.isLoading = false;
  }
}
```

### 5. 数据转换场景

#### 场景：API响应数据转换
```typescript
interface ApiResponse {
  id: string;
  attributes: {
    name: string;
    value: number;
  };
  relationships: {
    category: {
      data: { id: string; type: string };
    };
  };
}

interface LocalData {
  id: number;
  name: string;
  value: number;
  categoryId: string;
}

class DataTransformer {
  static transformResponse(response: ApiResponse): LocalData {
    return {
      id: parseInt(response.id),
      name: response.attributes.name,
      value: response.attributes.value,
      categoryId: response.relationships.category.data.id
    };
  }

  static transformBatch(responses: ApiResponse[]): LocalData[] {
    const result: LocalData[] = [];
    for (let i = 0; i < responses.length; i++) {
      result.push(DataTransformer.transformResponse(responses[i]));
    }
    return result;
  }
}
```

### 6. 事件处理模式

#### 场景：自定义事件系统
```typescript
interface EventData {
  type: string;
  payload: Object;
}

interface EventHandler {
  (data: EventData): void;
}

class EventManager {
  private static listeners: Map<string, EventHandler[]> = new Map();

  static addListener(eventType: string, handler: EventHandler): void {
    const handlers = EventManager.listeners.get(eventType);
    if (handlers) {
      handlers.push(handler);
    } else {
      EventManager.listeners.set(eventType, [handler]);
    }
  }

  static removeListener(eventType: string, handler: EventHandler): void {
    const handlers = EventManager.listeners.get(eventType);
    if (handlers) {
      for (let i = handlers.length - 1; i >= 0; i--) {
        if (handlers[i] === handler) {
          handlers.splice(i, 1);
        }
      }
    }
  }

  static emit(eventData: EventData): void {
    const handlers = EventManager.listeners.get(eventData.type);
    if (handlers) {
      for (let i = 0; i < handlers.length; i++) {
        handlers[i](eventData);
      }
    }
  }
}
```

## 🔧 性能优化建议

### 1. 避免不必要的对象创建
```typescript
// ❌ 频繁创建临时对象
function processItems(items: string[]): number {
  let sum = 0;
  for (let i = 0; i < items.length; i++) {
    const temp = { value: parseInt(items[i]) }; // 每次循环都创建新对象
    sum += temp.value;
  }
  return sum;
}

// ✅ 避免临时对象创建
function processItems(items: string[]): number {
  let sum = 0;
  for (let i = 0; i < items.length; i++) {
    sum += parseInt(items[i]);
  }
  return sum;
}
```

### 2. 缓存计算结果
```typescript
class Calculator {
  private static cache: Map<string, number> = new Map();

  static expensiveCalculation(input: string): number {
    const cached = Calculator.cache.get(input);
    if (cached !== undefined) {
      return cached;
    }

    // 模拟复杂计算
    let result = 0;
    for (let i = 0; i < 1000; i++) {
      result += input.length * i;
    }
    
    Calculator.cache.set(input, result);
    return result;
  }
}
```

### 3. 批量操作优化
```typescript
interface DataItem {
  id: number;
  value: string;
}

// ❌ 多次单独操作
function updateItemsIndividually(items: DataItem[]): void {
  for (let i = 0; i < items.length; i++) {
    updateSingleItem(items[i]);
  }
}

// ✅ 批量操作
function updateItemsBatch(items: DataItem[]): void {
  const updates: string[] = [];
  for (let i = 0; i < items.length; i++) {
    updates.push(`UPDATE items SET value = '${items[i].value}' WHERE id = ${items[i].id}`);
  }
  executeBatch(updates);
}
```

## 📋 检查清单

在提交代码前，请确认：

- [ ] 没有使用 `any` 或 `unknown` 类型
- [ ] 没有使用索引签名 `[key: string]: T`
- [ ] 没有使用内联对象字面量类型
- [ ] 对象访问使用明确的属性名，而非动态索引
- [ ] 对象遍历使用传统循环而非 `for...in`
- [ ] 所有对象都有明确的接口定义
- [ ] 静态方法中使用 `ClassName.method()` 而非 `this.method()`
- [ ] 没有使用解构赋值 `const [a, b] = array`
- [ ] 没有使用展开运算符 `...`
- [ ] 没有使用可选链操作符 `?.`
- [ ] 没有使用空值合并操作符 `??`
- [ ] 所有函数都有明确的返回类型注解
- [ ] 复杂类型的变量都有明确的类型注解

## 🚨 常见编译错误及解决方案

### Error: Property access is not allowed
**原因**：使用了动态索引访问
**解决**：使用switch语句或Map替代

### Error: Index signature is not allowed
**原因**：定义了索引签名
**解决**：使用Map或Record类型

### Error: Object literal type is not allowed
**原因**：使用了内联对象类型
**解决**：预定义接口

### Error: 'this' cannot be used in static context
**原因**：静态方法中使用了this
**解决**：使用类名.方法名调用

### Error: Destructuring assignment is not allowed
**原因**：使用了解构赋值语法
**解决**：使用传统的逐个赋值方式

### Error: Spread operator is not allowed
**原因**：使用了展开运算符
**解决**：使用显式的数组/对象操作

### Error: Optional chaining is not allowed
**原因**：使用了可选链操作符
**解决**：使用显式的null/undefined检查

### Error: Nullish coalescing is not allowed
**原因**：使用了空值合并操作符
**解决**：使用显式的null/undefined检查和三元运算符

### Error: Return type annotation is required
**原因**：函数缺少返回类型注解
**解决**：为函数添加明确的返回类型

## 📚 最佳实践总结

### 1. 代码组织
- 将相关接口组织在同一文件或专门接口文件中
- 使用清晰的命名约定，接口使用 `I` 前缀或描述性名称
- 类名使用 PascalCase，方法和变量使用 camelCase

### 2. 类型设计
- 优先使用组合而非继承
- 使用联合类型限制值的范围
- 为可选属性提供明确的默认值

### 3. 错误处理
- 使用明确的错误类型而非字符串错误
- 提供详细的错误信息和错误代码
- 在关键操作点添加适当的错误检查

### 4. 性能考虑
- 避免在循环中创建不必要的对象
- 使用缓存机制存储重复计算结果
- 批量操作优于多次单独操作

### 5. 可维护性
- 保持函数和类的单一职责
- 添加适当的注释说明复杂逻辑
- 使用有意义的变量和方法名

## 🎯 迁移指南

### 从 TypeScript 到 ArkTS 的常见修改

#### 1. 类型定义修改
```typescript
// TypeScript 原代码
interface UserData {
  [key: string]: any;
  name?: string;
}

// ArkTS 修改后
interface UserData {
  name: string;
  // 移除索引签名，明确所有属性
}
```

#### 2. 循环语句修改
```typescript
// TypeScript 原代码
for (const key in userData) {
  console.log(userData[key]);
}

// ArkTS 修改后
const keys = Object.keys(userData) as (keyof UserData)[];
for (let i = 0; i < keys.length; i++) {
  const key = keys[i];
  console.log(userData[key]);
}
```

#### 3. 对象操作修改
```typescript
// TypeScript 原代码
const combined = { ...obj1, ...obj2 };
const [first, second] = array;

// ArkTS 修改后
const combined: CombinedType = {
  prop1: obj1.prop1,
  prop2: obj2.prop2
};
const first = array[0];
const second = array[1];
```

#### 4. 静态方法修改
```typescript
// TypeScript 原代码
class Manager {
  private static data = [];
  
  static process() {
    this.data.push(item);
    return this.data;
  }
}

// ArkTS 修改后
class Manager {
  private static data = [];
  
  static process() {
    Manager.data.push(item);
    return Manager.data;
  }
}
```

## 📖 参考资源

- [HarmonyOS ArkTS 官方文档](https://developer.harmonyos.com/)
- [ArkTS 语言规范](https://developer.harmonyos.com/docs/docs/doc-code/ArkTS-ts-0000001280801036)
- [鸿蒙应用开发最佳实践](https://developer.harmonyos.com/docs/docs/doc-code/ets-guidelines-0000001158361223)

---

*本文档将持续更新，请遵循最新版本进行开发。如有疑问，请参考官方文档或联系开发团队。*