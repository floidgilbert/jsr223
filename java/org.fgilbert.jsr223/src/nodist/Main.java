package nodist;

// https://stackoverflow.com/questions/23230854/getting-unknown-number-of-dimensions-from-a-multidimensional-array-in-java

//import java.lang.reflect.Array;
//import java.lang.reflect.Method;
//
//import java.math.BigDecimal;
//import java.math.BigInteger;
//
import java.util.Arrays;
import java.util.ArrayList;
//import java.util.Collection;
//import java.util.Iterator;
//import java.util.Map;
import java.util.List;
//
//
import org.fgilbert.jdx.*;
import org.fgilbert.jdx.JavaToR.ArrayOrder;
//import org.fgilbert.jsr223.*;
import org.fgilbert.jsr223.Controller;

class Main {

	public static void main(String[] args) {
//		Integer[][][][][] array = {{{{{null, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, null}}}}, {{{{null, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}}, {{{0, 1, 2}, {null, 1, 2}}, {{0, 1, 2}, {0, 1, null}}}}};
//		Integer[][][] array = {{{0, 1, 2}, {0, 1, 2}}, {{0, 1, 2}, {0, 1, 2}}};
//		int[][][] array = {{{1,2,3},{4,5,6},{7,8,9}},{{10,11,12},{13,14,15},{16,17,18}},{{19,20,21},{22,23,24},{25,26,27}}};
//		int[][][] array = {{{1,10,19},{4,13,22},{7,16,25}},{{2,11,20},{5,14,23},{8,17,26}},{{3,12,21},{6,15,24},{9,18,27}}};
//		int[][][] array = {{{1, 4, 7}, {2, 5, 8}, {3, 6, 9}}, {{10, 13, 16}, {11, 14, 17}, {12, 15, 18}}, {{19, 22, 25}, {20, 23, 26}, {21, 24, 27}}};
//		JavaToR j2r = new JavaToR(array, ArrayOrder.ROW_MAJOR_JAVA);
//		Object[] r = j2r.getValueObjectArray1d();
//		System.out.println(r.length);
//		j2r = new JavaToR(new String[][] {{}}, ArrayOrder.COLUMN_MAJOR);
//		j2r = new JavaToR(new String[][] {}, ArrayOrder.ROW_MAJOR);
//		j2r = new JavaToR(new String[][] {}, ArrayOrder.ROW_MAJOR_JAVA);
//		JavaToR j2r = new JavaToR(new int[][] {{}}, ArrayOrder.ROW_MAJOR);
//		Object[] r = j2r.getValueObjectArray1d();
//		System.out.println(r.length);
//		Object o = new int[] {};
//		System.out.println(o.getClass().getName());
		System.out.println(Double.TYPE.equals(double.class));
	}
	
	public static void mainXMX(String[] args) {
//		Object[] oa = {1, 2.2, "3"};
//		ArrayList<Object> col = new ArrayList<Object>(Arrays.asList(oa));
//		List<Object> col = Arrays.asList(oa);
//		Iterator<?> iter = col.iterator();
//		Object o = iter.next();
//		System.out.println(o.getClass().isArray());
//		System.out.println(o.getClass().isArray());
//		List<Object> a = Arrays.asList(oa);
//		JavaToR j2r = new JavaToR(oa);
//		Object[] o2 = j2r.getValueObjectArray1d();
//		System.out.println(j2r.getRdataCompositeCode());
		int[][] n = {};
		Class<?> o = n.getClass();
		System.out.println(n.length);
		System.out.println(o.getComponentType().isArray());
	}
	
	public static int[] oneD() {
		int[] n = {1, 2, 3};
		return n;
	}
	
	public static int[][] twoD() {
		int[][] n = {{1, 2, 3}, {4, 5, 6}};
//		int[][] n = {{1}};
		return n;
	}
	
	public static int[][][] threeD() {
		int[][][] n = {{{1, 2, 3}, {4, 5, 6}}, {{1, 2, 3}, {4, 5, 6}}};
		return n;
	}
	
	public static int getNumberOfDimensions(Class<?> type) {
		int n = -1;
		do {
			type = type.getComponentType();
			n++;
		} while (type != null);
		return n;
    }
	
	public static void mainXI(String[] args) {
//		int[] n = oneD();
//		int[][] nn = twoD();
//		int[][][] nnn = threeD();
//		//java.util.ArrayList<int[]> c = Array.newInstance(componentType, dimensions);
//		n = Arrays.stream(nn).flatMapToInt(Arrays::stream).toArray();
//		System.out.println(Arrays.toString(n));		
//		n = Arrays.stream(nnn).flatMapToInt(Arrays::stream).toArray();
//		System.out.println(Arrays.toString(n));		
		return;
	}

	
	public static Integer[] flatten(Object[] inputArray) throws IllegalArgumentException {

        if (inputArray == null) return null;

        List<Integer> flatList = new ArrayList<Integer>();

        for (Object element : inputArray) {
            if (element instanceof Integer) {
                flatList.add((Integer) element);
            } else if (element instanceof Object[]) {
                flatList.addAll(Arrays.asList(flatten((Object[]) element)));
            } else {
                throw new IllegalArgumentException("Input must be an array of Integers or nested arrays of Integers");
            }
        }
        return flatList.toArray(new Integer[flatList.size()]);
    }
	
	public static void mainSMS(String[] args) {
		String c = "abc";
		Object o = c;
		System.out.println(o.toString());
		
//		int[] n = {1,2,3,3,4};
//		int[] ns = Arrays.stream(n).map((int i) -> {if (i == 3) return 0; else return i;}).toArray();
//		System.out.println(Arrays.toString(n));
//		System.out.println(Arrays.toString(ns));
		
//		Object a = new Object();
//		int[] n = oneD();
//		String[] s = {"alex"};
//		Object[][] o = {{"abc"}};
//		System.out.println(o.getClass().getComponentType().getComponentType());
//		int[][] nn = twoD();
//		int[][][] nnn = threeD();
//		int[][][][] nnnn = {};
//		System.out.println(Array.getLength(nn));
//		Class<?> c = null;
		return;
	}
	
	public static void mainSLX(String[] args) {
//		Object o = Utility.createNdimensionalArray(new int[] {1, 2, 3, 4}, new int[] {2, 2}, false);
		int max = 32;
		int[] data = new int[max];
		for (int i = 0; i < max; i++)
			data[i] = i + 1;
		int[] dimensions = new int[] {1, 1, 0};
		Object o = Utility.createNdimensionalArrayRowMajor(data, dimensions);
		o = Utility.createNdimensionalArrayColumnMajor(data, dimensions);
//		int[][][] n = (int[][][]) o; 
//		System.out.println(n[0][0].length);
		System.out.println(o.getClass().getName());
		return;
	}
	
	public static void mainFFF(String[] args) {
		Controller controller = null;
		try {
			controller = new Controller("js");
//			controller.putEvaluationRequest("var a = [[1,null],[2,'b']];", true);
//			controller.putEvaluationRequest("var ArrayListClass = Java.type('java.util.ArrayList');var a = new ArrayListClass();var LinkedHashMapClass = Java.type('java.util.LinkedHashMap');var m = new LinkedHashMapClass();m.put('a', 'a');m.put('b', 2);a.add(m);", true);
//			controller.putEvaluationRequest("var ArrayListClass = Java.type('java.util.ArrayList');", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var LinkedHashMapClass = Java.type('java.util.LinkedHashMap');", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var a = new ArrayListClass(2)", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("var m = new LinkedHashMapClass();", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m.put('a', 3); m.put('b', 2); a.add(m);", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m = new LinkedHashMapClass();", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
//			controller.putEvaluationRequest("m.put('a', null); m.put('b', 2); a.add(m);", true);
//			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate. 
			controller.putEvaluationRequest("var a = {'a':1, 'b':2, 'c':'abc'}", true);
			controller.waitForEvaluation(); // IMPORTANT: If you forget to execute this after putEvaluationRequest, the thread won't terminate.
//			controller.setScriptEngineValue("a", new boolean[] {});
//			JavaToR j2r = controller.getResponse();
			int typeCode = controller.getScriptEngineValue("a");
			System.out.println(String.format("%X", typeCode));
//			Object o = controller.getResponse().getValueObject();
//			System.out.println(String.format("%X", typeCode));
//			System.out.println(controller.getScriptEngineValueClassName("a"));
//			System.out.println(controller.getResponseInteger());
//			controller.putEvaluationRequest("true;", false);
//			typeCode = controller.waitForEvaluation();
//			System.out.println(typeCode);
//			System.out.println(controller.getResponseBoolean());

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			if (controller != null)
				try {
					controller.terminate();
				} catch (InterruptedException e) {
					e.printStackTrace();
				}
		}
	}
}
